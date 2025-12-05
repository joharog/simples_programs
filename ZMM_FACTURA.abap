*&---------------------------------------------------------------------*
*& Report ZMM_FACTURA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmm_factura.

TABLES: vbrk, vbrp, kna1, t189t, prcd_elements .

DATA:
  ls_data TYPE zmm_factura,
  lt_data TYPE TABLE OF zmm_factura.
*----------------------------------------------------------------------*
*  A L V  -  D E F I N I T I O N
*----------------------------------------------------------------------*
DATA:
  gt_slis_group    TYPE slis_t_sp_group_alv,
  gt_slis_fieldcat TYPE slis_t_fieldcat_alv,
  gs_slis_layout   TYPE slis_layout_alv,
  gt_slis_header   TYPE slis_t_listheader.
*----------------------------------------------------------------------*

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  SELECT-OPTIONS:  s_vkorg FOR vbrp-vkorg_ana,
                   s_fkdat FOR vbrp-fkdat_ana,
                   s_kdgrp FOR vbrp-kdgrp_auft,
                   s_kunag FOR vbrp-kunag_ana,
                   s_vbeln FOR vbrp-vbeln, " DEFAULT '6000079927',
                   s_matnr FOR vbrp-matnr.
SELECTION-SCREEN: END OF BLOCK b1.

START-OF-SELECTION.

  SELECT * FROM vbrk INTO TABLE @DATA(lt_vbrk)
    WHERE vbeln IN @s_vbeln
      AND vkorg IN @s_vkorg
      AND fkdat IN @s_fkdat
      AND kdgrp IN @s_kdgrp
      AND kunag IN @s_kunag.

  IF sy-subrc EQ 0.
    SELECT * FROM vbrp INTO TABLE @DATA(lt_vbrp)
      FOR ALL ENTRIES IN @lt_vbrk
      WHERE vbeln      EQ @lt_vbrk-vbeln
        AND matnr      IN @s_matnr
        AND vkorg_ana  EQ @lt_vbrk-vkorg
        AND fkdat_ana  EQ @lt_vbrk-fkdat
        AND kdgrp_auft EQ @lt_vbrk-kdgrp
        AND kunag_ana  EQ @lt_vbrk-kunag.

    SELECT * FROM kna1 INTO TABLE @DATA(lt_kna1)
      FOR ALL ENTRIES IN @lt_vbrk
      WHERE kunnr EQ @lt_vbrk-kunag.

    SELECT * FROM t189t INTO TABLE @DATA(lt_t189t)
      FOR ALL ENTRIES IN @lt_vbrk
      WHERE pltyp EQ @lt_vbrk-pltyp.

    SELECT * FROM prcd_elements
      INTO TABLE @DATA(lt_elements)
      FOR ALL ENTRIES IN @lt_vbrk
      WHERE knumv EQ @lt_vbrk-knumv
        AND kschl EQ 'ZP03'.
  ENDIF.

  SORT lt_vbrp BY vbeln aupos.
  LOOP AT lt_vbrp INTO DATA(ls_vbrp).

    ls_data-aupos = ls_vbrp-aupos.
    ls_data-matnr = ls_vbrp-matnr.
    ls_data-arktx = ls_vbrp-arktx.
    ls_data-fkimg = ls_vbrp-fkimg.
    ls_data-vrkme = ls_vbrp-vrkme.
    ls_data-netwr = ls_vbrp-netwr / ls_vbrp-fkimg.
    ls_data-waerk = ls_vbrp-waerk.


    READ TABLE lt_vbrk INTO DATA(ls_vbrk) WITH KEY vbeln = ls_vbrp-vbeln.
    IF sy-subrc EQ 0.
      ls_data-vbeln = ls_vbrk-vbeln.
      ls_data-fkdat = ls_vbrk-fkdat.
      ls_data-kunag = ls_vbrk-kunag.
      ls_data-kdgrp = ls_vbrk-kdgrp.
      ls_data-pltyp = ls_vbrk-pltyp.
      ls_data-fkart = ls_vbrk-fkart.

        SELECT SINGLE KTEXT INTO ls_data-VTEXT
         FROM T151T
          WHERE KDGRP  =  ls_data-kdgrp and SPRAS = 'S'.

       CASE  ls_data-fkart.

       WHEN 'GG02'.
         ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'GG03'.
          ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'GG04'.
          ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'GG05'.
          ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'GR01'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'GR02'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'GR03'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'GR04'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'GR05'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'ZA02'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'ZA07'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'ZG02'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'ZG07'.
          ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'ZG08'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'ZR02'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'ZR05'.
          ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'ZR07'.
           ls_data-fkimg =  ls_data-fkimg * -1.
       WHEN 'ZR08'.
           ls_data-fkimg =  ls_data-fkimg * -1.
      ENDCASE.


      READ TABLE lt_kna1 INTO DATA(ls_kna1) WITH KEY kunnr = ls_vbrk-kunag.
      IF sy-subrc EQ 0.
        ls_data-name1 = ls_kna1-name1.
      ENDIF.

      READ TABLE lt_t189t INTO DATA(ls_t189t) WITH KEY pltyp = ls_vbrk-pltyp.
      IF sy-subrc EQ 0.
        ls_data-ptext = ls_t189t-ptext.
      ENDIF.

      READ TABLE lt_elements INTO DATA(ls_elements) WITH KEY knumv = ls_vbrk-knumv kposn = ls_vbrp-aupos.
      IF sy-subrc EQ 0.
        ls_data-kbetr = ls_elements-kbetr.
        ls_data-waers = ls_elements-waers.
      ENDIF.
    ENDIF.

    IF ls_data-kbetr <> 0.
      ls_data-valr = ( ( ls_data-netwr - ls_data-kbetr ) / ls_data-kbetr ) * 100 .
    ELSE.
      ls_data-valr = ''.
    ENDIF.


    ls_data-valus = ls_data-netwr - ls_data-kbetr.

    ls_data-totaus = ls_data-fkimg * ls_data-valus.

    APPEND ls_data TO lt_data.
    CLEAR: ls_data, ls_vbrp, ls_vbrk, ls_kna1, ls_t189t, ls_elements.

  ENDLOOP.

END-of-SELECTION.

  PERFORM alv.
*&---------------------------------------------------------------------*
*& Form ALV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM alv .
  PERFORM alv_group.
  PERFORM alv_fieldcat.
  PERFORM alv_layout.
  PERFORM alv_display.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_GROUP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_group .
  APPEND VALUE #( sp_group = 'A'
                    text     = TEXT-001 )
                    TO gt_slis_group.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_fieldcat .
  REFRESH gt_slis_fieldcat.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = sy-repid
      i_internal_tabname     = 'ZMM_FACTURA'
      i_structure_name       = 'ZMM_FACTURA'
      i_bypassing_buffer     = 'X'
      i_buffer_active        = ' '
    CHANGING
      ct_fieldcat            = gt_slis_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  LOOP AT gt_slis_fieldcat ASSIGNING FIELD-SYMBOL(<fs_fieldcat>).

    CASE <fs_fieldcat>-fieldname.
      WHEN 'VBELN'.
        <fs_fieldcat>-seltext_s = 'Nro. Factura'.
        <fs_fieldcat>-seltext_m = 'Nro. Factura'.
        <fs_fieldcat>-seltext_l = 'Nro. Factura'.
      WHEN 'NAME1'.
        <fs_fieldcat>-seltext_s = 'Nombre Cliente'.
        <fs_fieldcat>-seltext_m = 'Nombre Cliente'.
        <fs_fieldcat>-seltext_l = 'Nombre Cliente'.
      WHEN 'MATNR'.
        <fs_fieldcat>-seltext_s = 'Cod. Material'.
        <fs_fieldcat>-seltext_m = 'Cod. Material'.
        <fs_fieldcat>-seltext_l = 'Cod. Material'.
      WHEN 'ARKTX'.
        <fs_fieldcat>-reptext_ddic = 'Material Descripción'.
        <fs_fieldcat>-seltext_s = 'Material Des.'.
        <fs_fieldcat>-seltext_m = 'Material Descripción'.
        <fs_fieldcat>-seltext_l = 'Material Descripción'.
      WHEN 'FKIMG'.
        <fs_fieldcat>-seltext_s = 'Cantidad'.
        <fs_fieldcat>-seltext_m = 'Cantidad'.
        <fs_fieldcat>-seltext_l = 'Cantidad'.
      WHEN 'PLTYP'.
        <fs_fieldcat>-seltext_s = 'Tipo Lista Precio'.
        <fs_fieldcat>-seltext_m = 'Tipo Lista Precio'.
        <fs_fieldcat>-seltext_l = 'Tipo Lista Precio'.
      WHEN 'PTEXT'.
        <fs_fieldcat>-reptext_ddic = 'Nombre Lista Precio'.
        <fs_fieldcat>-seltext_s = 'Nom. Lista'.
        <fs_fieldcat>-seltext_m = 'Nombre Lista Precio'.
        <fs_fieldcat>-seltext_l = 'Nombre Lista Precio'.
      WHEN 'NETWR'.
        <fs_fieldcat>-reptext_ddic = 'Precio Facturado'.
        <fs_fieldcat>-seltext_s = 'Precio Facturado'.
        <fs_fieldcat>-seltext_m = 'Precio Facturado'.
        <fs_fieldcat>-seltext_l = 'Precio Facturado'.
      WHEN 'KBETR'.
        <fs_fieldcat>-seltext_s = 'Precio Lista'.
        <fs_fieldcat>-seltext_m = 'Precio Lista'.
        <fs_fieldcat>-seltext_l = 'Precio Lista'.
      WHEN 'VALR'.
        <fs_fieldcat>-seltext_s = 'Variación %'.
        <fs_fieldcat>-seltext_m = 'Variación %'.
        <fs_fieldcat>-seltext_l = 'Variación %'.
      WHEN 'VALUS'.
        <fs_fieldcat>-reptext_ddic = 'Var Precio USD'.
        <fs_fieldcat>-seltext_s = 'Var Precio USD'.
        <fs_fieldcat>-seltext_m = 'Var Precio USD'.
        <fs_fieldcat>-seltext_l = 'Var Precio USD'.
      WHEN 'TOTAUS'.
        <fs_fieldcat>-reptext_ddic = 'Total USD'.
        <fs_fieldcat>-seltext_s = 'Total USD'.
        <fs_fieldcat>-seltext_m = 'Total USD'.
        <fs_fieldcat>-seltext_l = 'Total USD'.

      WHEN 'VTEXT'.
        <fs_fieldcat>-reptext_ddic = 'Descripción Grp cliente'.
        <fs_fieldcat>-seltext_s = 'Descripción Grp cliente'.
        <fs_fieldcat>-seltext_m = 'Descripción Grp cliente'.
        <fs_fieldcat>-seltext_l = 'Descripción Grp cliente'.

    ENDCASE.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_layout .
  CLEAR gs_slis_layout.
  gs_slis_layout-colwidth_optimize   = 'X'.
  gs_slis_layout-zebra               = 'X'.
*  gs_slis_layout-box_fieldname       = 'CHECK'.
*  gs_slis_layout-get_selinfos        = 'X'.
*  gs_slis_layout-f2code              = 'BEAN' .
*  gs_slis_layout-confirmation_prompt = 'X'.
*  gs_slis_layout-key_hotspot         = 'X'.
*  gs_slis_layout-info_fieldname      = 'COL'.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_display.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
*     i_callback_top_of_page   = 'TOP_OF_PAGE'
*     i_callback_pf_status_set = 'PF_STATUS'
*     i_callback_user_command  = 'USER_COMMAND'
      is_layout          = gs_slis_layout
      it_fieldcat        = gt_slis_fieldcat
      it_special_groups  = gt_slis_group
      i_save             = 'X'
    TABLES
      t_outtab           = lt_data.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.
