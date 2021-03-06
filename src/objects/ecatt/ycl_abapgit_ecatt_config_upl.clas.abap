CLASS ycl_abapgit_ecatt_config_upl DEFINITION
  PUBLIC
  INHERITING FROM cl_apl_ecatt_config_upload
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS:
      z_set_stream_for_upload
        IMPORTING
          iv_xml TYPE xstring.

  PROTECTED SECTION.
    METHODS:
      upload_data_from_stream REDEFINITION.

  PRIVATE SECTION.
    DATA: mv_external_xml TYPE xstring.

ENDCLASS.



CLASS ycl_abapgit_ecatt_config_upl IMPLEMENTATION.


  METHOD upload_data_from_stream.

    " Downport
    template_over_all = ycl_abapgit_ecatt_helper=>upload_data_from_stream( mv_external_xml ).

  ENDMETHOD.


  METHOD z_set_stream_for_upload.

    " downport from CL_ABAPGIT_ECATT_DATA_UPLOAD SET_STREAM_FOR_UPLOAD
    mv_external_xml = iv_xml.

  ENDMETHOD.
ENDCLASS.
