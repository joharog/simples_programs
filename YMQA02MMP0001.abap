*&---------------------------------------------------------------------*
*& Report YMQA_TEST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ymqa02mmp0001.
TABLES: mara, lfm1, ekko, ekpo, t024, t001, t001w, marc, tcurc.

DATA: lt_fieldcat TYPE lvc_t_fcat.
DATA: it_excluding TYPE STANDARD TABLE OF ui_func,
      wa_exclude   TYPE ui_func.

wa_exclude = cl_gui_alv_grid=>mc_fc_loc_delete_row. "Atributo boton de informacion "mc_fc_info
APPEND wa_exclude TO it_excluding.

CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
  EXPORTING
    i_structure_name       = 'YMQA02MMTB001'
  CHANGING
    ct_fieldcat            = lt_fieldcat
  EXCEPTIONS
    inconsistent_interface = 1
    program_error          = 2
    OTHERS                 = 3.
IF sy-subrc <> 0.
  RETURN.
ENDIF.

LOOP AT lt_fieldcat ASSIGNING FIELD-SYMBOL(<fs_fieldcat>).
  IF <fs_fieldcat>-fieldname EQ 'FECHA_CREACION' OR <fs_fieldcat>-fieldname EQ 'FECHA_MODIFICACION'.
    <fs_fieldcat>-edit = abap_false.
  ELSE.
    <fs_fieldcat>-edit = abap_true.
  ENDIF.
ENDLOOP.

SELECT * FROM ymqa02mmtb001
  INTO TABLE @DATA(lt_tarifas).

SORT lt_tarifas BY contrato poscontrato FECHA_INICIO..

DATA(lt_original_tarifas) = lt_tarifas.

DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'CONTAINER_ALV' ).

DATA(lo_grid) = NEW cl_gui_alv_grid( i_parent = lo_container ).

lo_grid->set_table_for_first_display(
  EXPORTING
    it_toolbar_excluding         = it_excluding
    i_structure_name              = 'YMQA02MMTB001'
  CHANGING
    it_outtab                     = lt_tarifas
    it_fieldcatalog               = lt_fieldcat

  EXCEPTIONS
    invalid_parameter_combination = 1
    program_error                 = 2
    too_many_lines                = 3
    OTHERS                        = 4
).
IF sy-subrc <> 0.
  RETURN.
ENDIF.

CALL SCREEN 1000.

lo_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_enter ).

lo_grid->set_ready_for_input( i_ready_for_input = 1 ).




INCLUDE ymqa02mmp0001_status.
*INCLUDE ymqa_test_status_1000o01.

INCLUDE ymqa02mmp0001_user_command.
*INCLUDE ymqa_test_user_command_1000i01.


*&---------------------------------------------------------------------*
*& Form check_row
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_row.

  DATA: lv_msg TYPE char255.

  DATA: ls_tarifas_negociadas1 TYPE zws_tarifas_negociadas1,
        ls_tarifas_negociadas  TYPE zws_tarifas_negociadas,
        lt_tarifas_ws          TYPE TABLE OF zws_tarifas_negociadas_tarifas,
        ls_tarifas_ws          TYPE zws_tarifas_negociadas_tarifas,
        ls_header              TYPE zws_tarifas_negociadas_header,
        lt_items               TYPE TABLE OF zws_tarifas_negociadas_items,
        ls_items               TYPE zws_tarifas_negociadas_items.

  DATA: lt_temp TYPE TABLE OF ymqa02mmtb001.

  DATA: lv_con TYPE ebeln.
  DATA: lv_pos TYPE ebelp.

  CLEAR: lt_tarifas_ws[], ls_tarifas_negociadas.

  LOOP AT lt_tarifas INTO DATA(ls_tarifas).

*    REFRESH: lt_temp.

    READ TABLE lt_original_tarifas INTO DATA(ls_original) WITH KEY contrato = ls_tarifas-contrato poscontrato = ls_tarifas-poscontrato FECHA_INICIO = ls_tarifas-FECHA_INICIO.

    ls_tarifas-mandt = sy-mandt.

    "Verifica si ya existe el contrato y posicion, realiza la modificacion.
    IF sy-subrc EQ 0.

      CLEAR: lv_msg.

      IF ls_original <> ls_tarifas.

        IF ls_tarifas-contrato IS NOT INITIAL.
          SELECT SINGLE * FROM ekko WHERE ebeln EQ ls_tarifas-contrato.
          IF sy-subrc NE 0.
            lv_msg =  | Contrato { ls_tarifas-contrato } no existe en la tabla EKPO |.
            MESSAGE lv_msg TYPE 'E'.
          ENDIF.

          IF ls_tarifas-poscontrato EQ '00000'.
            lv_msg =  | Pos. Contrato no puede estar vacio |.
            MESSAGE lv_msg TYPE 'E'.
          ELSE.
            IF ls_tarifas-poscontrato IS NOT INITIAL.
              SELECT SINGLE * FROM ekpo WHERE ebeln EQ ls_tarifas-contrato AND ebelp EQ ls_tarifas-poscontrato.
              IF sy-subrc NE 0.
                lv_msg =  | Pos. Contrato { ls_tarifas-poscontrato } no existe para Contrato { ls_tarifas-contrato }|.
                MESSAGE lv_msg TYPE 'E'.
              ENDIF.

              IF ls_tarifas-centro IS NOT INITIAL.
*    SELECT SINGLE * FROM t001w WHERE werks EQ ls_tarifas-centro.
                SELECT SINGLE * FROM ekpo
                   WHERE ebeln EQ ls_tarifas-contrato
                     AND ebelp EQ ls_tarifas-poscontrato
                     AND werks EQ ls_tarifas-centro.
                IF sy-subrc NE 0.
                  lv_msg =  | Centro { ls_tarifas-centro } no corresponde al contrato { ls_tarifas-contrato } |.
                  MESSAGE lv_msg TYPE 'E'.
                ENDIF.
              ENDIF.

              IF ls_tarifas-material IS NOT INITIAL.
*      SELECT SINGLE * FROM mara WHERE matnr EQ ls_tarifas-material.
                SELECT SINGLE * FROM ekpo
                  WHERE matnr EQ ls_tarifas-material
                    AND ebeln EQ ls_tarifas-contrato
                    AND ebelp EQ ls_tarifas-poscontrato.
                IF sy-subrc NE 0.
                  lv_msg =  | Material { ls_tarifas-material } no corresponde al contrato { ls_tarifas-contrato } |.
                  MESSAGE lv_msg TYPE 'E'.
                ENDIF.

                IF ls_tarifas-umedida IS NOT INITIAL.
*            SELECT SINGLE * FROM mara WHERE meins EQ ls_tarifas-umedida.
                  SELECT SINGLE * FROM ekpo
                    WHERE meins EQ ls_tarifas-umedida
                      AND ebeln EQ ls_tarifas-contrato
                      AND ebelp EQ ls_tarifas-poscontrato.
                  IF sy-subrc NE 0.
                    lv_msg =  | UM base { ls_tarifas-umedida } no existe no corresponde al contrato { ls_tarifas-contrato } |.
                    MESSAGE lv_msg TYPE 'E'.
                  ENDIF.
                ENDIF.
              ELSE.
                MESSAGE 'Debe insertar un material valido' TYPE 'E'.
              ENDIF.
            ENDIF.
          ENDIF.


          IF ls_tarifas-proveedor IS NOT INITIAL.
*      SELECT SINGLE * FROM lfm1 WHERE lifnr EQ ls_tarifas-proveedor AND ekorg EQ ls_tarifas-orgcompra.
            SELECT SINGLE * FROM ekko
              WHERE ebeln EQ ls_tarifas-contrato
                AND lifnr EQ ls_tarifas-proveedor.
            IF sy-subrc NE 0.
              lv_msg =  | Proveedor { ls_tarifas-proveedor } no corresponde al contrato { ls_tarifas-contrato } |.
              MESSAGE lv_msg TYPE 'E'.
            ENDIF.
          ENDIF.

          IF ls_tarifas-orgcompra IS NOT INITIAL.
*      SELECT SINGLE * FROM lfm1 WHERE lifnr EQ ls_tarifas-proveedor AND ekorg EQ ls_tarifas-orgcompra.
            SELECT SINGLE * FROM ekko
               WHERE ebeln EQ ls_tarifas-contrato
                 AND ekorg EQ ls_tarifas-orgcompra.
            IF sy-subrc NE 0.
              lv_msg =  | Org. Compras { ls_tarifas-orgcompra } no corresponde al contrato { ls_tarifas-contrato } |.
              MESSAGE lv_msg TYPE 'E'.
            ENDIF.
          ENDIF.

          IF ls_tarifas-moneda IS NOT INITIAL.
*    SELECT SINGLE * FROM tcurc WHERE waers EQ ls_tarifas-moneda.
            SELECT SINGLE * FROM ekko
           WHERE ebeln EQ ls_tarifas-contrato
             AND waers EQ ls_tarifas-moneda.
            IF sy-subrc NE 0.
              lv_msg =  | Moneda { ls_tarifas-moneda } no corresponde al contrato { ls_tarifas-contrato } |.
              MESSAGE lv_msg TYPE 'E'.
            ENDIF.
          ENDIF.
        ENDIF.

        IF ls_tarifas-grpcompra IS NOT INITIAL.
          SELECT SINGLE * FROM t024 WHERE ekgrp EQ ls_tarifas-grpcompra.
          IF sy-subrc NE 0.
            lv_msg =  | Gr. Compras { ls_tarifas-grpcompra } no existe en la tabla T024 |.
            MESSAGE lv_msg TYPE 'E'.
          ENDIF.
        ENDIF.

        IF ls_tarifas-sociedad IS NOT INITIAL.
          SELECT SINGLE * FROM t001 WHERE bukrs EQ ls_tarifas-sociedad.
          IF sy-subrc NE 0.
            lv_msg =  | Gr. Compras { ls_tarifas-sociedad } no existe en la tabla T001 |.
            MESSAGE lv_msg TYPE 'E'.
          ENDIF.
        ENDIF.

        IF ls_tarifas-fecha_creacion IS NOT INITIAL.
          ls_tarifas-fecha_modificacion = sy-datum.
        ENDIF.

        IF ls_tarifas-fecha_creacion IS INITIAL.
          ls_tarifas-fecha_creacion = sy-datum.
        ENDIF.

*        ls_items-pos_contrato  = ls_tarifas-poscontrato.
*        ls_items-material      = |{ ls_tarifas-material ALPHA = OUT }|.
*        ls_items-um            = ls_tarifas-umedida.
*        ls_items-centro        = ls_tarifas-centro.
*        ls_items-tipo_servicio = ls_tarifas-tiposerv.
*        ls_items-precio_base   = ls_tarifas-precbase.
*        ls_items-tarifa        = ls_tarifas-tarifa.
*        ls_items-cantidad_base = ls_tarifas-cantidad_base.
*        ls_items-fecha_inicio  = ls_tarifas-fecha_inicio.
*        ls_items-fecha_final   = ls_tarifas-fecha_final.
*        ls_items-activo        = ls_tarifas-activo.
*        APPEND ls_items TO lt_items.

*        ls_header-contrato           = ls_tarifas-contrato.
*        ls_header-proveedor          = ls_tarifas-proveedor.
*        ls_header-org_compra         = ls_tarifas-orgcompra.
*        ls_header-moneda             = ls_tarifas-moneda.
*        ls_header-grp_compra         = ls_tarifas-grpcompra.
*        ls_header-sociedad           = ls_tarifas-sociedad.
*        ls_header-fecha_creacion     = ls_tarifas-fecha_creacion.
*        ls_header-fecha_modificacion = ls_tarifas-fecha_modificacion.
*        ls_header-items              = lt_items.
*
*        ls_tarifas_ws-header = ls_header.
*
*        APPEND ls_tarifas_ws TO lt_tarifas_ws.
*
*        ls_tarifas_negociadas-tarifas = lt_tarifas_ws.
*
*        ls_tarifas_negociadas1-tarifas_negociadas = ls_tarifas_negociadas.
*
        APPEND ls_tarifas TO lt_temp.
*        MODIFY ymqa02mmtb001 FROM TABLE lt_temp.
*        COMMIT WORK.
        CLEAR: ls_tarifas.
      ELSE.
*        READ TABLE lt_original_tarifas INTO ls_original WITH KEY contrato = ls_tarifas-contrato poscontrato = ls_tarifas-poscontrato.
*        IF sy-subrc EQ 0.
*          lv_msg =  | Ya existe la entrada con contrato { ls_tarifas-contrato } y posicion { ls_tarifas-poscontrato } |.
*          MESSAGE lv_msg TYPE 'E'.
*        ENDIF.

      ENDIF.

      "Si no existe contrato y posicion inserta nuevo registro.
    ELSE.

      CLEAR: lv_msg.
      ls_tarifas-contrato    = |{ ls_tarifas-contrato ALPHA = IN }|.
      ls_tarifas-poscontrato = |{ ls_tarifas-poscontrato  ALPHA = IN }|.

      CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
        EXPORTING
          input  = ls_tarifas-material
        IMPORTING
          output = ls_tarifas-material.

*      ls_tarifas-material    = |{ ls_tarifas-material  ALPHA = IN }|.
      ls_tarifas-proveedor   = |{ ls_tarifas-proveedor  ALPHA = IN }|.

      IF ls_tarifas-contrato IS NOT INITIAL.
        SELECT SINGLE * FROM ekko WHERE ebeln EQ ls_tarifas-contrato.
        IF sy-subrc NE 0.
          lv_msg =  | Contrato { ls_tarifas-contrato } no existe en la tabla EKPO |.
          MESSAGE lv_msg TYPE 'E'.
        ENDIF.

        IF ls_tarifas-poscontrato EQ '00000'.
          lv_msg =  | Pos. Contrato no puede estar vacio |.
          MESSAGE lv_msg TYPE 'E'.
        ELSE.
          IF ls_tarifas-poscontrato IS NOT INITIAL.
            SELECT SINGLE * FROM ekpo WHERE ebeln EQ ls_tarifas-contrato AND ebelp EQ ls_tarifas-poscontrato.
            IF sy-subrc NE 0.
              lv_msg =  | Pos. Contrato { ls_tarifas-poscontrato } no existe para Contrato { ls_tarifas-contrato }|.
              MESSAGE lv_msg TYPE 'E'.
            ENDIF.

            IF ls_tarifas-centro IS NOT INITIAL.
*    SELECT SINGLE * FROM t001w WHERE werks EQ ls_tarifas-centro.
              SELECT SINGLE * FROM ekpo
                 WHERE ebeln EQ ls_tarifas-contrato
                   AND ebelp EQ ls_tarifas-poscontrato
                   AND werks EQ ls_tarifas-centro.
              IF sy-subrc NE 0.
                lv_msg =  | Centro { ls_tarifas-centro } no corresponde al contrato { ls_tarifas-contrato } |.
                MESSAGE lv_msg TYPE 'E'.
              ENDIF.
            ENDIF.

            IF ls_tarifas-material IS NOT INITIAL.
*      SELECT SINGLE * FROM mara WHERE matnr EQ ls_tarifas-material.
              SELECT SINGLE * FROM ekpo
                WHERE matnr EQ ls_tarifas-material
                  AND ebeln EQ ls_tarifas-contrato
                  AND ebelp EQ ls_tarifas-poscontrato.
              IF sy-subrc NE 0.
                lv_msg =  | Material { ls_tarifas-material } no corresponde al contrato { ls_tarifas-contrato } |.
                MESSAGE lv_msg TYPE 'E'.
              ENDIF.

              IF ls_tarifas-umedida IS NOT INITIAL.
*            SELECT SINGLE * FROM mara WHERE meins EQ ls_tarifas-umedida.
                SELECT SINGLE * FROM ekpo
                  WHERE meins EQ ls_tarifas-umedida
                    AND ebeln EQ ls_tarifas-contrato
                    AND ebelp EQ ls_tarifas-poscontrato.
                IF sy-subrc NE 0.
                  lv_msg =  | UM base { ls_tarifas-umedida } no existe no corresponde al contrato { ls_tarifas-contrato } |.
                  MESSAGE lv_msg TYPE 'E'.
                ENDIF.
              ENDIF.
            ELSE.
              MESSAGE 'Debe insertar un material valido' TYPE 'E'.
            ENDIF.
          ENDIF.
        ENDIF.


        IF ls_tarifas-proveedor IS NOT INITIAL.
*      SELECT SINGLE * FROM lfm1 WHERE lifnr EQ ls_tarifas-proveedor AND ekorg EQ ls_tarifas-orgcompra.
          SELECT SINGLE * FROM ekko
            WHERE ebeln EQ ls_tarifas-contrato
              AND lifnr EQ ls_tarifas-proveedor.
          IF sy-subrc NE 0.
            lv_msg =  | Proveedor { ls_tarifas-proveedor } no corresponde al contrato { ls_tarifas-contrato } |.
            MESSAGE lv_msg TYPE 'E'.
          ENDIF.
        ENDIF.

        IF ls_tarifas-orgcompra IS NOT INITIAL.
*      SELECT SINGLE * FROM lfm1 WHERE lifnr EQ ls_tarifas-proveedor AND ekorg EQ ls_tarifas-orgcompra.
          SELECT SINGLE * FROM ekko
             WHERE ebeln EQ ls_tarifas-contrato
               AND ekorg EQ ls_tarifas-orgcompra.
          IF sy-subrc NE 0.
            lv_msg =  | Org. Compras { ls_tarifas-orgcompra } no corresponde al contrato { ls_tarifas-contrato } |.
            MESSAGE lv_msg TYPE 'E'.
          ENDIF.
        ENDIF.

        IF ls_tarifas-moneda IS NOT INITIAL.
*    SELECT SINGLE * FROM tcurc WHERE waers EQ ls_tarifas-moneda.
          SELECT SINGLE * FROM ekko
         WHERE ebeln EQ ls_tarifas-contrato
           AND waers EQ ls_tarifas-moneda.
          IF sy-subrc NE 0.
            lv_msg =  | Moneda { ls_tarifas-moneda } no corresponde al contrato { ls_tarifas-contrato } |.
            MESSAGE lv_msg TYPE 'E'.
          ENDIF.
        ENDIF.
      ENDIF.

      IF ls_tarifas-grpcompra IS NOT INITIAL.
        SELECT SINGLE * FROM t024 WHERE ekgrp EQ ls_tarifas-grpcompra.
        IF sy-subrc NE 0.
          lv_msg =  | Gr. Compras { ls_tarifas-grpcompra } no existe en la tabla T024 |.
          MESSAGE lv_msg TYPE 'E'.
        ENDIF.
      ENDIF.

      IF ls_tarifas-sociedad IS NOT INITIAL.
        SELECT SINGLE * FROM t001 WHERE bukrs EQ ls_tarifas-sociedad.
        IF sy-subrc NE 0.
          lv_msg =  | Gr. Compras { ls_tarifas-sociedad } no existe en la tabla T001 |.
          MESSAGE lv_msg TYPE 'E'.
        ENDIF.
      ENDIF.

      IF ls_tarifas-fecha_creacion IS NOT INITIAL.
        ls_tarifas-fecha_modificacion = sy-datum.
      ENDIF.

      IF ls_tarifas-fecha_creacion IS INITIAL .
        ls_tarifas-fecha_creacion = sy-datum .
      ENDIF.

*      "Si llego a este punto no hubieron errores de verififacion.
*      ls_items-pos_contrato  = ls_tarifas-poscontrato.
*      ls_items-material      = |{ ls_tarifas-material ALPHA = OUT }|.
*      ls_items-um            = ls_tarifas-umedida.
*      ls_items-centro        = ls_tarifas-centro.
*      ls_items-tipo_servicio = ls_tarifas-tiposerv.
*      ls_items-precio_base   = ls_tarifas-precbase.
*      ls_items-tarifa        = ls_tarifas-tarifa.
*      ls_items-cantidad_base = ls_tarifas-cantidad_base.
*      ls_items-fecha_inicio  = ls_tarifas-fecha_inicio.
*      ls_items-fecha_final   = ls_tarifas-fecha_final.
*      ls_items-activo        = ls_tarifas-activo.
*      APPEND ls_items TO lt_items.

*      ls_header-contrato           = ls_tarifas-contrato.
*      ls_header-proveedor          = ls_tarifas-proveedor.
*      ls_header-org_compra         = ls_tarifas-orgcompra.
*      ls_header-moneda             = ls_tarifas-moneda.
*      ls_header-grp_compra         = ls_tarifas-grpcompra.
*      ls_header-sociedad           = ls_tarifas-sociedad.
*      ls_header-fecha_creacion     = ls_tarifas-fecha_creacion.
*      ls_header-fecha_modificacion = ls_tarifas-fecha_modificacion.
*      ls_header-items              = lt_items.
*
*      ls_tarifas_ws-header = ls_header.
*
*      APPEND ls_tarifas_ws TO lt_tarifas_ws.
*
*      ls_tarifas_negociadas-tarifas = lt_tarifas_ws.
*
*      ls_tarifas_negociadas1-tarifas_negociadas = ls_tarifas_negociadas.
*
      APPEND ls_tarifas TO lt_temp.
*      MODIFY ymqa02mmtb001 FROM TABLE lt_temp.
*      COMMIT WORK.
      CLEAR: ls_tarifas.
    ENDIF.

  ENDLOOP.



  SORT lt_temp BY contrato poscontrato.

  LOOP AT lt_temp INTO DATA(ls_temp).

    AT NEW contrato.
      DATA(f_new) = abap_true.
    ENDAT.

    IF f_new IS NOT INITIAL.
      f_new = abap_false.
      DATA(lt_aux1) = lt_temp[].
      DELETE lt_aux1 WHERE contrato NE ls_temp-contrato.
*      SORT lt_aux1 DESCENDING BY poscontrato.
      READ TABLE lt_aux1 INTO DATA(ls_aux1) INDEX sy-tfill.
      IF sy-subrc EQ 0.
        lv_pos = ls_aux1-poscontrato.
      ENDIF.
    ENDIF.

    ls_items-pos_contrato  = ls_temp-poscontrato.
    ls_items-material      = |{ ls_temp-material ALPHA = OUT }|.
    ls_items-material      = |{ condense( ls_items-material ) }|.
    ls_items-um            = ls_temp-umedida.
    ls_items-centro        = ls_temp-centro.
    ls_items-tipo_servicio = ls_temp-tiposerv.
    ls_items-precio_base   = ls_temp-precbase.
    ls_items-tarifa        = ls_temp-tarifa.
    ls_items-cantidad_base = ls_temp-cantidad_base.
    ls_items-fecha_inicio  = ls_temp-fecha_inicio.
    ls_items-fecha_final   = ls_temp-fecha_final.
    ls_items-activo        = ls_temp-activo.
    APPEND ls_items TO lt_items.

    ls_header-proveedor          = COND #( WHEN ls_temp-proveedor IS NOT INITIAL THEN ls_temp-proveedor ).
    ls_header-org_compra         = COND #( WHEN ls_temp-orgcompra IS NOT INITIAL THEN ls_temp-orgcompra ).
    ls_header-moneda             = COND #( WHEN ls_temp-moneda IS NOT INITIAL THEN ls_temp-moneda ).
    ls_header-grp_compra         = COND #( WHEN ls_temp-grpcompra IS NOT INITIAL THEN ls_temp-grpcompra ).
    ls_header-sociedad           = COND #( WHEN ls_temp-sociedad IS NOT INITIAL THEN ls_temp-sociedad ).

    ls_header-fecha_creacion     = COND #( WHEN ls_temp-fecha_creacion IS NOT INITIAL THEN ls_temp-fecha_creacion ).
    ls_header-fecha_modificacion = ls_temp-fecha_modificacion.
    ls_header-contrato           = ls_temp-contrato.

    IF lv_pos = ls_temp-poscontrato.
      ls_header-items              = lt_items.
      ls_tarifas_ws-header         = ls_header.
      APPEND ls_tarifas_ws TO lt_tarifas_ws.
      ls_tarifas_negociadas-tarifas = lt_tarifas_ws.
      CLEAR: lt_items[], ls_items, ls_tarifas_ws.
    ENDIF.

    CLEAR: ls_temp.
  ENDLOOP.

  MODIFY ymqa02mmtb001 FROM TABLE lt_temp.
  COMMIT WORK.


  CLEAR ls_tarifas_negociadas1-tarifas_negociadas.
  ls_tarifas_negociadas1-tarifas_negociadas = ls_tarifas_negociadas.


*  IF lt_tarifas_ws IS NOT INITIAL.
*    ls_tarifas_negociadas-tarifas             = lt_tarifas_ws.
*    ls_tarifas_negociadas1-tarifas_negociadas = ls_tarifas_negociadas.
*  ENDIF.


  DATA: lo_tarifa        TYPE REF TO zws_co_tarifas_negociadas,
        lo_sys_exception TYPE REF TO cx_ai_system_fault,
        gs_output        TYPE zws_tarifas_negociadas1.

  IF ls_tarifas_negociadas1 IS NOT INITIAL.
    gs_output = ls_tarifas_negociadas1.

    TRY.
        CREATE OBJECT lo_tarifa.

        CALL METHOD lo_tarifa->tarifas_negociadas
          EXPORTING
            input = gs_output.

      CATCH cx_ai_system_fault INTO lo_sys_exception.
        lo_sys_exception->if_message~get_text( ).

    ENDTRY.

    COMMIT WORK AND WAIT.

    CLEAR:gs_output,  ls_tarifas_negociadas1,lt_temp.

  ENDIF.


  REFRESH lt_tarifas.
  SELECT * FROM ymqa02mmtb001
   INTO TABLE lt_tarifas.

  delete lt_tarifas where contrato eq space and poscontrato eq space.

  SORT lt_tarifas BY contrato poscontrato FECHA_INICIO.

  lt_original_tarifas = lt_tarifas.

  CALL METHOD lo_grid->refresh_table_display.
ENDFORM.
