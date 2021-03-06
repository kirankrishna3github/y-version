CLASS ycl_abapgit_persist_settings DEFINITION
  PUBLIC
  CREATE PRIVATE .

  PUBLIC SECTION.

    METHODS modify
      IMPORTING
        !io_settings TYPE REF TO ycl_abapgit_settings
      RAISING
        ycx_abapgit_exception .
    METHODS read
      RETURNING
        VALUE(ro_settings) TYPE REF TO ycl_abapgit_settings .
    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_settings) TYPE REF TO ycl_abapgit_persist_settings .
  PRIVATE SECTION.

    DATA mo_settings TYPE REF TO ycl_abapgit_settings .
    CLASS-DATA go_persist TYPE REF TO ycl_abapgit_persist_settings .
ENDCLASS.



CLASS ycl_abapgit_persist_settings IMPLEMENTATION.


  METHOD get_instance.

    IF go_persist IS NOT BOUND.
      CREATE OBJECT go_persist.
    ENDIF.
    ro_settings = go_persist.

  ENDMETHOD.


  METHOD modify.

    DATA: lv_settings      TYPE string,
          ls_user_settings TYPE yif_abapgit_definitions=>ty_s_user_settings.


    lv_settings = io_settings->get_settings_xml( ).

    ycl_abapgit_persistence_db=>get_instance( )->modify(
      iv_type       = ycl_abapgit_persistence_db=>c_type_settings
      iv_value      = ''
      iv_data       = lv_settings ).

    ls_user_settings = io_settings->get_user_settings( ).

    ycl_abapgit_persistence_user=>get_instance( )->set_settings( ls_user_settings ).

    " Settings have been modified: Update Buffered Settings
    IF mo_settings IS BOUND.
      mo_settings->set_xml_settings( lv_settings ).
      mo_settings->set_user_settings( ls_user_settings ).
    ENDIF.

  ENDMETHOD.


  METHOD read.

    IF mo_settings IS BOUND.
      " Return Buffered Settings
      ro_settings = mo_settings.
      RETURN.
    ENDIF.

    " Settings have changed or have not yet been loaded
    CREATE OBJECT ro_settings.

    TRY.

        ro_settings->set_xml_settings(
          ycl_abapgit_persistence_db=>get_instance( )->read(
            iv_type  = ycl_abapgit_persistence_db=>c_type_settings
            iv_value = '' ) ).

        ro_settings->set_user_settings( ycl_abapgit_persistence_user=>get_instance( )->get_settings( ) ).

      CATCH ycx_abapgit_not_found ycx_abapgit_exception.

        ro_settings->set_defaults( ).

    ENDTRY.

    mo_settings = ro_settings.

  ENDMETHOD.
ENDCLASS.
