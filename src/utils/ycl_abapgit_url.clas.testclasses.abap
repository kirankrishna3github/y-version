CLASS ltcl_test DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS:
      repo_host FOR TESTING RAISING ycx_abapgit_exception,
      repo_name1 FOR TESTING RAISING ycx_abapgit_exception,
      repo_name2 FOR TESTING RAISING ycx_abapgit_exception,
      repo_error FOR TESTING.

ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD repo_error.

    TRY.
        ycl_abapgit_url=>host( 'not a real url' ).          "#EC NOTEXT
        cl_abap_unit_assert=>fail( ).
      CATCH ycx_abapgit_exception.                      "#EC NO_HANDLER
    ENDTRY.

  ENDMETHOD.

  METHOD repo_host.

    DATA: lv_host TYPE string.

    lv_host = ycl_abapgit_url=>host( 'https://github.com/larshp/Foobar.git' ).

    cl_abap_unit_assert=>assert_equals(
        exp = 'https://github.com'
        act = lv_host ).

  ENDMETHOD.

  METHOD repo_name1.

    DATA: lv_name TYPE string.

    lv_name = ycl_abapgit_url=>name( 'https://github.com/larshp/Foobar.git' ).

    cl_abap_unit_assert=>assert_equals(
        exp = 'Foobar'
        act = lv_name ).

  ENDMETHOD.

  METHOD repo_name2.

    DATA: lv_name TYPE string.

    lv_name = ycl_abapgit_url=>name( 'https://git.hanatrial.ondemand.com/p12345trial/yay' ).

    cl_abap_unit_assert=>assert_equals(
        exp = 'yay'
        act = lv_name ).

  ENDMETHOD.

ENDCLASS.