CLASS ycl_abapgit_gui_page_db_dis DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC INHERITING FROM ycl_abapgit_gui_page.

  PUBLIC SECTION.
    INTERFACES: yif_abapgit_gui_page_hotkey.

    METHODS: constructor
      IMPORTING is_key TYPE yif_abapgit_persistence=>ty_content.

    CLASS-METHODS: render_record_banner
      IMPORTING is_key         TYPE yif_abapgit_persistence=>ty_content
      RETURNING VALUE(rv_html) TYPE string.

  PROTECTED SECTION.
    METHODS render_content REDEFINITION.

  PRIVATE SECTION.
    DATA: ms_key TYPE yif_abapgit_persistence=>ty_content.

ENDCLASS.



CLASS YCL_ABAPGIT_GUI_PAGE_DB_DIS IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).
    ms_key = is_key.
    ms_control-page_title = 'CONFIG DISPLAY'.
  ENDMETHOD.


  METHOD render_content.

    DATA:
      lo_highlighter TYPE REF TO ycl_abapgit_syntax_highlighter,
      lo_toolbar     TYPE REF TO ycl_abapgit_html_toolbar,
      lv_data        TYPE yif_abapgit_persistence=>ty_content-data_str,
      ls_action      TYPE yif_abapgit_persistence=>ty_content,
      lv_action      TYPE string.

    TRY.
        lv_data = ycl_abapgit_persistence_db=>get_instance( )->read(
          iv_type = ms_key-type
          iv_value = ms_key-value ).
      CATCH ycx_abapgit_not_found ##NO_HANDLER.
    ENDTRY.

    " Create syntax highlighter
    lo_highlighter  = ycl_abapgit_syntax_highlighter=>create( '*.xml' ).

    ls_action-type  = ms_key-type.
    ls_action-value = ms_key-value.
    lv_action       = ycl_abapgit_html_action_utils=>dbkey_encode( ls_action ).
    lv_data         = lo_highlighter->process_line( ycl_abapgit_xml_pretty=>print( lv_data ) ).

    CREATE OBJECT ro_html.
    CREATE OBJECT lo_toolbar.
    lo_toolbar->add( iv_act = |{ yif_abapgit_definitions=>c_action-db_edit }?{ lv_action }|
                     iv_txt = 'Edit' ) ##NO_TEXT.

    ro_html->add( '<div class="db_entry">' ).
    ro_html->add( '<table class="toolbar"><tr><td>' ).
    ro_html->add( render_record_banner( ms_key ) ).
    ro_html->add( '</td><td>' ).
    ro_html->add( lo_toolbar->render( iv_right = abap_true ) ).
    ro_html->add( '</td></tr></table>' ).

    ro_html->add( |<pre class="syntax-hl">{ lv_data }</pre>| ).
    ro_html->add( '</div>' ).

  ENDMETHOD.  "render_content


  METHOD render_record_banner.
    rv_html = |<table class="tag"><tr><td class="label">Type:</td>|
           && | <td>{ is_key-type }</td></tr></table>|
           && yif_abapgit_definitions=>c_newline
           && |<table class="tag"><tr><td class="label">Key:</td>|
           && |  <td>{ is_key-value }</td></tr></table>|.
  ENDMETHOD. "render_record_banner


  METHOD yif_abapgit_gui_page_hotkey~get_hotkey_actions.

  ENDMETHOD.
ENDCLASS.
