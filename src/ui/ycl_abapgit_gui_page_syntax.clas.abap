CLASS ycl_abapgit_gui_page_syntax DEFINITION PUBLIC FINAL CREATE PUBLIC
    INHERITING FROM ycl_abapgit_gui_page_codi_base.

  PUBLIC SECTION.
    INTERFACES: yif_abapgit_gui_page_hotkey.

    METHODS:
      constructor
        IMPORTING io_repo TYPE REF TO ycl_abapgit_repo.

  PROTECTED SECTION.

    METHODS:
      render_content REDEFINITION.

ENDCLASS.



CLASS YCL_ABAPGIT_GUI_PAGE_SYNTAX IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).
    ms_control-page_title = 'SYNTAX CHECK'.
    mo_repo = io_repo.
  ENDMETHOD.  " constructor.


  METHOD render_content.

    DATA: li_syntax_check TYPE REF TO yif_abapgit_code_inspector.
    FIELD-SYMBOLS: <ls_result> LIKE LINE OF mt_result.

    li_syntax_check = ycl_abapgit_factory=>get_syntax_check( iv_package = mo_repo->get_package( ) ).

    mt_result = li_syntax_check->run( ).

    CREATE OBJECT ro_html.
    ro_html->add( '<div class="toc">' ).

    IF lines( mt_result ) = 0.
      ro_html->add( 'No errors' ).
    ENDIF.

    LOOP AT mt_result ASSIGNING <ls_result>.
      render_result( ro_html   = ro_html iv_result = <ls_result> ).
    ENDLOOP.

    ro_html->add( '</div>' ).

  ENDMETHOD.  "render_content


  METHOD yif_abapgit_gui_page_hotkey~get_hotkey_actions.

  ENDMETHOD.
ENDCLASS.
