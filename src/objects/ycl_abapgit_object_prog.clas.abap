CLASS ycl_abapgit_object_prog DEFINITION PUBLIC INHERITING FROM ycl_abapgit_objects_program FINAL.

  PUBLIC SECTION.
    INTERFACES yif_abapgit_object.
    ALIASES mo_files FOR yif_abapgit_object~mo_files.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_tpool_i18n,
             language TYPE langu,
             textpool TYPE yif_abapgit_definitions=>ty_tpool_tt,
           END OF ty_tpool_i18n,
           tt_tpool_i18n TYPE STANDARD TABLE OF ty_tpool_i18n.
    CONSTANTS: c_longtext_id_prog TYPE dokil-id VALUE 'RE'.

    METHODS:
      serialize_texts
        IMPORTING io_xml TYPE REF TO ycl_abapgit_xml_output
        RAISING   ycx_abapgit_exception,
      deserialize_texts
        IMPORTING io_xml TYPE REF TO ycl_abapgit_xml_input
        RAISING   ycx_abapgit_exception,
      is_program_locked
        RETURNING
          VALUE(rv_is_program_locked) TYPE abap_bool
        RAISING
          ycx_abapgit_exception.

ENDCLASS.



CLASS ycl_abapgit_object_prog IMPLEMENTATION.


  METHOD deserialize_texts.

    DATA: lt_tpool_i18n TYPE tt_tpool_i18n,
          lt_tpool      TYPE textpool_table.

    FIELD-SYMBOLS <ls_tpool> LIKE LINE OF lt_tpool_i18n.


    io_xml->read( EXPORTING iv_name = 'I18N_TPOOL'
                  CHANGING  cg_data = lt_tpool_i18n ).

    LOOP AT lt_tpool_i18n ASSIGNING <ls_tpool>.
      lt_tpool = read_tpool( <ls_tpool>-textpool ).
      deserialize_textpool( iv_program  = ms_item-obj_name
                            iv_language = <ls_tpool>-language
                            it_tpool    = lt_tpool ).
    ENDLOOP.

  ENDMETHOD.


  METHOD is_program_locked.

    rv_is_program_locked = exists_a_lock_entry_for( iv_lock_object = 'ESRDIRE'
                                                    iv_argument    = |{ ms_item-obj_name }| ).

  ENDMETHOD.


  METHOD serialize_texts.

    DATA: lt_tpool_i18n TYPE tt_tpool_i18n,
          lt_tpool      TYPE textpool_table.

    FIELD-SYMBOLS <ls_tpool> LIKE LINE OF lt_tpool_i18n.


    " Table d010tinf stores info. on languages in which program is maintained
    " Select all active translations of program texts
    " Skip master language - it was already serialized
    SELECT DISTINCT language
      INTO CORRESPONDING FIELDS OF TABLE lt_tpool_i18n
      FROM d010tinf
      WHERE r3state = 'A'
      AND   prog = ms_item-obj_name
      AND   language <> mv_language.

    SORT lt_tpool_i18n BY language ASCENDING.
    LOOP AT lt_tpool_i18n ASSIGNING <ls_tpool>.
      READ TEXTPOOL ms_item-obj_name
        LANGUAGE <ls_tpool>-language
        INTO lt_tpool.
      <ls_tpool>-textpool = add_tpool( lt_tpool ).
    ENDLOOP.

    IF lines( lt_tpool_i18n ) > 0.
      io_xml->add( iv_name = 'I18N_TPOOL'
                   ig_data = lt_tpool_i18n ).
    ENDIF.

  ENDMETHOD.


  METHOD yif_abapgit_object~changed_by.
    SELECT SINGLE unam FROM reposrc INTO rv_user
      WHERE progname = ms_item-obj_name
      AND r3state = 'A'.
    IF sy-subrc <> 0.
      rv_user = c_user_unknown.
    ENDIF.
  ENDMETHOD.


  METHOD yif_abapgit_object~compare_to_remote_version.
    CREATE OBJECT ro_comparison_result TYPE ycl_abapgit_comparison_null.
  ENDMETHOD.


  METHOD yif_abapgit_object~delete.

    DATA: lv_program LIKE sy-repid.

    lv_program = ms_item-obj_name.

    CALL FUNCTION 'RS_DELETE_PROGRAM'
      EXPORTING
        program                    = lv_program
        suppress_popup             = abap_true
        force_delete_used_includes = abap_true
      EXCEPTIONS
        enqueue_lock               = 1
        object_not_found           = 2
        permission_failure         = 3
        reject_deletion            = 4
        OTHERS                     = 5.

    IF sy-subrc <> 0.
      ycx_abapgit_exception=>raise( |Error from RS_DELETE_PROGRAM: { sy-subrc }| ).
    ENDIF.

    delete_longtexts( c_longtext_id_prog ).

  ENDMETHOD.


  METHOD yif_abapgit_object~deserialize.

    DATA: lv_program_name TYPE programm,
          ls_progdir      TYPE ty_progdir,
          lt_tpool        TYPE textpool_table,
          lt_dynpros      TYPE ty_dynpro_tt,
          lt_tpool_ext    TYPE yif_abapgit_definitions=>ty_tpool_tt,
          ls_cua          TYPE ty_cua,
          lt_source       TYPE abaptxt255_tab.

    lv_program_name = ms_item-obj_name.

    lt_source = mo_files->read_abap( ).

    io_xml->read( EXPORTING iv_name = 'TPOOL'
                  CHANGING cg_data = lt_tpool_ext ).
    lt_tpool = read_tpool( lt_tpool_ext ).

    io_xml->read( EXPORTING iv_name = 'PROGDIR'
                  CHANGING cg_data  = ls_progdir ).
    deserialize_program( is_progdir = ls_progdir
                         it_source  = lt_source
                         it_tpool   = lt_tpool
                         iv_package = iv_package ).

    io_xml->read( EXPORTING iv_name = 'DYNPROS'
                  CHANGING cg_data  = lt_dynpros ).
    deserialize_dynpros( lt_dynpros ).

    io_xml->read( EXPORTING iv_name = 'CUA'
                  CHANGING cg_data  = ls_cua ).
    deserialize_cua( iv_program_name = lv_program_name
                     is_cua = ls_cua ).

    " Texts deserializing (English)
    deserialize_textpool( iv_program = lv_program_name
                          it_tpool   = lt_tpool ).

    " Texts deserializing (translations)
    deserialize_texts( io_xml ).

    deserialize_longtexts( io_xml ).

  ENDMETHOD.


  METHOD yif_abapgit_object~exists.

    DATA: lv_progname TYPE reposrc-progname.

    SELECT SINGLE progname FROM reposrc INTO lv_progname
      WHERE progname = ms_item-obj_name
      AND r3state = 'A'.
    rv_bool = boolc( sy-subrc = 0 ).

  ENDMETHOD.


  METHOD yif_abapgit_object~get_metadata.
    rs_metadata = get_metadata( ).
  ENDMETHOD.


  METHOD yif_abapgit_object~has_changed_since.

    rv_changed = check_prog_changed_since(
      iv_program   = ms_item-obj_name
      iv_timestamp = iv_timestamp ).

  ENDMETHOD.


  METHOD yif_abapgit_object~is_locked.

    IF is_program_locked( )                     = abap_true
    OR is_any_dynpro_locked( ms_item-obj_name ) = abap_true
    OR is_cua_locked( ms_item-obj_name )        = abap_true
    OR is_text_locked( ms_item-obj_name )       = abap_true.

      rv_is_locked = abap_true.

    ENDIF.

  ENDMETHOD.


  METHOD yif_abapgit_object~jump.

    CALL FUNCTION 'RS_TOOL_ACCESS'
      EXPORTING
        operation     = 'SHOW'
        object_name   = ms_item-obj_name
        object_type   = 'PROG'
        in_new_window = abap_true.

  ENDMETHOD.


  METHOD yif_abapgit_object~serialize.

* see SAP note 1025291, run report DELETE_TADIR_FOR_EIMP_INCLUDE to clean bad TADIR entries
    ASSERT NOT ms_item-obj_name CP '*=E'.

    serialize_program( io_xml   = io_xml
                       is_item  = ms_item
                       io_files = mo_files ).

    " Texts serializing (translations)
    serialize_texts( io_xml ).

    serialize_longtexts( io_xml         = io_xml
                         iv_longtext_id = c_longtext_id_prog ).

  ENDMETHOD.
ENDCLASS.
