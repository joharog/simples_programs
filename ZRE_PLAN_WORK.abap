*&---------------------------------------------------------------------*
*& Report ZRE_PLAN_WORK
*&---------------------------------------------------------------------*

REPORT zre_plan_work.

* Structure Decleration
DATA: it_plan_work TYPE TABLE OF zst_plan_work,
      ls_plan_work TYPE zst_plan_work,
      return       TYPE bapiret2,
      lv_filename  TYPE char100,
      lv_boomi     TYPE int4.

DATA: lt_selected_files TYPE filetable,
      lv_rc             TYPE i,
      lt_file_content   TYPE STANDARD TABLE OF string,
      lv_file           TYPE string,
      lt_columns        TYPE TABLE OF string.

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_file LIKE rlgrap-filename DEFAULT 'C:\filename.csv'. ##NO_TEXT
SELECTION-SCREEN END OF BLOCK b01.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title     = 'Select CSV File'
      default_filename = '*.csv'
      file_filter      = '*.csv'
    CHANGING
      file_table       = lt_selected_files
      rc               = lv_rc
    EXCEPTIONS
      cntl_error       = 1
      error_no_gui     = 2
      OTHERS           = 3.

  IF lv_rc = 1.
    READ TABLE lt_selected_files INDEX 1 INTO lv_file.
    p_file = lv_file.
  ENDIF.


START-OF-SELECTION.
  PERFORM upload_file.

END-OF-SELECTION.


FORM upload_file.

  IF p_file IS NOT INITIAL.

    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename      = lv_file
        filetype      = 'ASC'
      CHANGING
        data_tab      = lt_file_content
      EXCEPTIONS
        access_denied = 1
        error_no_gui  = 2
        OTHERS        = 3.

    IF sy-subrc = 0.
      LOOP AT lt_file_content INTO DATA(lv_line).

        REFRESH: lt_columns.
        CLEAR: ls_plan_work.

        IF sy-tabix NE 1.
          CALL FUNCTION 'RSDS_CONVERT_CSV'
            EXPORTING
              i_record      = lv_line
              i_data_sep    = ',' " Specify your separator
              i_esc_char    = '"' " Specify your escape character
              i_field_count = '4'
            IMPORTING
              e_t_data      = lt_columns.

          " Map the columns to your internal table structure
          READ TABLE lt_columns INTO ls_plan_work-id INDEX 1.
          READ TABLE lt_columns INTO ls_plan_work-emx_task_card INDEX 2.
          READ TABLE lt_columns INTO ls_plan_work-emx_skill INDEX 3.
          READ TABLE lt_columns INTO ls_plan_work-emx_work INDEX 4.

          APPEND ls_plan_work TO it_plan_work.
        ENDIF.

      ENDLOOP.

    ENDIF.

  ENDIF.


  IF it_plan_work[] IS NOT INITIAL.

    lv_filename = p_file.

    DESCRIBE TABLE it_plan_work LINES lv_boomi.

    CALL FUNCTION 'ZFM_PLAN_WORK'
      EXPORTING
        it_plan_work = it_plan_work
        reg_boomi    = lv_boomi
        name_file    = lv_filename
      IMPORTING
        return       = return.

  ENDIF.

  IF return IS NOT INITIAL.
    MESSAGE return-message TYPE 'S' DISPLAY LIKE return-type.
  ELSE.
    "Default message
  ENDIF.

ENDFORM.
