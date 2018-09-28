CLASS ycl_abapgit_object_auth DEFINITION PUBLIC INHERITING FROM ycl_abapgit_objects_super FINAL.

  PUBLIC SECTION.
    INTERFACES yif_abapgit_object.
    ALIASES mo_files FOR yif_abapgit_object~mo_files.
    METHODS constructor
      IMPORTING
        is_item     TYPE yif_abapgit_definitions=>ty_item
        iv_language TYPE spras.
  PRIVATE SECTION.
    DATA: mv_fieldname TYPE authx-fieldname.

ENDCLASS.



CLASS ycl_abapgit_object_auth IMPLEMENTATION.

  METHOD constructor.

    super->constructor( is_item     = is_item
                        iv_language = iv_language ).

    mv_fieldname = ms_item-obj_name.

  ENDMETHOD.


  METHOD yif_abapgit_object~changed_by.
* looks like "changed by user" is not stored in the database
    rv_user = c_user_unknown.
  ENDMETHOD.


  METHOD yif_abapgit_object~compare_to_remote_version.
    CREATE OBJECT ro_comparison_result TYPE ycl_abapgit_comparison_null.
  ENDMETHOD.


  METHOD yif_abapgit_object~delete.

    " there is a bug in SAP standard, the TADIR entries are not deleted
    " when the AUTH object is deleted in transaction SU20

    " FM SUSR_AUTF_DELETE_FIELD calls the UI, therefore we reimplement its logic

    DATA:
      lt_objlst TYPE susr_t_xuobject,
      lo_auth   TYPE REF TO cl_auth_tools,
      lv_dummy  TYPE string.

    " authority check
    CREATE OBJECT lo_auth.
    IF lo_auth->authority_check_suso( actvt     = '06'
                                      fieldname = mv_fieldname ) <> 0.
      MESSAGE e463(01) WITH mv_fieldname INTO lv_dummy.
      ycx_abapgit_exception=>raise_t100( ).
    ENDIF.

    " if field is used check
    lt_objlst = lo_auth->suso_where_used_afield( mv_fieldname ).
    IF lt_objlst IS NOT INITIAL.
      MESSAGE i453(01) WITH mv_fieldname INTO lv_dummy.
      ycx_abapgit_exception=>raise_t100( ).
    ENDIF.

    " collect fieldname into a transport task
    IF lo_auth->add_afield_to_trkorr( mv_fieldname ) <> 0.
      "no transport -> no deletion
      MESSAGE e507(0m) INTO lv_dummy.
      ycx_abapgit_exception=>raise_t100( ).
    ENDIF.

    DELETE FROM authx WHERE fieldname = mv_fieldname.
    IF sy-subrc <> 0.
      MESSAGE e507(0m) INTO lv_dummy.
      ycx_abapgit_exception=>raise_t100( ).
    ENDIF.

  ENDMETHOD.


  METHOD yif_abapgit_object~deserialize.
* see include LSAUT_FIELDF02

    DATA: ls_authx TYPE authx,
          lo_auth  TYPE REF TO cl_auth_tools.


    io_xml->read( EXPORTING iv_name = 'AUTHX'
                  CHANGING cg_data = ls_authx ).

    tadir_insert( iv_package ).

    CREATE OBJECT lo_auth.

    IF lo_auth->add_afield_to_trkorr( ls_authx-fieldname ) <> 0.
      ycx_abapgit_exception=>raise( 'Error deserializing AUTH' ).
    ENDIF.

    MODIFY authx FROM ls_authx.
    IF sy-subrc <> 0.
      ycx_abapgit_exception=>raise( 'Error deserializing AUTH' ).
    ENDIF.

    CALL FUNCTION 'DB_COMMIT'.
    lo_auth->set_authfld_info_from_db( ls_authx-fieldname ).

  ENDMETHOD.


  METHOD yif_abapgit_object~exists.

    SELECT SINGLE fieldname FROM authx
      INTO mv_fieldname
      WHERE fieldname = ms_item-obj_name.               "#EC CI_GENBUFF
    rv_bool = boolc( sy-subrc = 0 ).

  ENDMETHOD.


  METHOD yif_abapgit_object~get_metadata.
    rs_metadata = get_metadata( ).
  ENDMETHOD.


  METHOD yif_abapgit_object~has_changed_since.
    rv_changed = abap_true.
  ENDMETHOD.


  METHOD yif_abapgit_object~jump.

* TODO, this function module does not exist in 702
    CALL FUNCTION 'SU20_MAINTAIN_SNGL'
      EXPORTING
        id_field    = mv_fieldname
        id_wbo_mode = abap_false.

  ENDMETHOD.


  METHOD yif_abapgit_object~serialize.

    DATA: ls_authx TYPE authx.


    SELECT SINGLE * FROM authx INTO ls_authx
      WHERE fieldname = ms_item-obj_name.               "#EC CI_GENBUFF
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    io_xml->add( iv_name = 'AUTHX'
                 ig_data = ls_authx ).

  ENDMETHOD.

  METHOD yif_abapgit_object~is_locked.

    rv_is_locked = abap_false.

  ENDMETHOD.

ENDCLASS.