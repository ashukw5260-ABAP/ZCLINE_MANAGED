CLASS lcl_buffer IMPLEMENTATION.
  METHOD initialize.
    CLEAR: mt_create_po, mt_update_po, mt_delete_po,
           mt_create_item, mt_update_item, mt_delete_item.
  ENDMETHOD.

  METHOD clear_all.
    CLEAR: mt_create_po, mt_update_po, mt_delete_po,
           mt_create_item, mt_update_item, mt_delete_item.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_po IMPLEMENTATION.

  METHOD create_po.
    DATA: ls_po      TYPE zpo_hdr,
          lv_exists  TYPE xsdboolean,
          ls_msg     TYPE symsg.

    LOOP AT entities INTO DATA(ls_entity).
      " Validate mandatory key
      IF ls_entity-po_id IS INITIAL.
        APPEND VALUE #(
          %cid      = ls_entity-%cid
          %msg      = new_message( id = 'ZPO' number = '001' 
                                   v1 = 'PO_ID' )
        ) TO reported-po.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po.
        CONTINUE.
      ENDIF.

      " Check for duplicate in DB
      SELECT SINGLE @abap_true INTO lv_exists
        FROM zpo_hdr
        WHERE mandt = @sy-mandt
          AND po_id = @ls_entity-po_id.

      IF lv_exists = abap_true.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '002'
                              v1 = ls_entity-po_id )
        ) TO reported-po.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po.
        CONTINUE.
      ENDIF.

      " Prepare record for insert
      ls_po = CORRESPONDING #( ls_entity ).
      ls_po-mandt       = sy-mandt.
      ls_po-is_deleted  = ' '.
      ls_po-created_by  = sy-uname.
      ls_po-created_at  = utclong_now( ).
      ls_po-changed_by  = sy-uname.
      ls_po-changed_at  = utclong_now( ).

      " Add to create buffer
      APPEND ls_po TO lcl_buffer=>mt_create_po.

      " Set mapped
      APPEND VALUE #(
        %cid   = ls_entity-%cid
        po_id  = ls_entity-po_id
      ) TO mapped-po.
    ENDLOOP.
  ENDMETHOD.

  METHOD update_po.
    DATA: ls_po   TYPE zpo_hdr,
          lv_cnt  TYPE i,
          ls_msg  TYPE symsg.

    LOOP AT entities INTO DATA(ls_entity).
      " Check if PO exists and not deleted
      SELECT SINGLE @abap_true INTO DATA(lv_exists)
        FROM zpo_hdr
        WHERE mandt    = @sy-mandt
          AND po_id    = @ls_entity-po_id
          AND is_deleted = ' '.

      IF lv_exists IS NOT TRUE.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '003'
                              v1 = ls_entity-po_id )
        ) TO reported-po.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po.
        CONTINUE.
      ENDIF.

      " Prepare record for update
      ls_po = CORRESPONDING #( ls_entity ).
      ls_po-mandt      = sy-mandt.
      ls_po-changed_by = sy-uname.
      ls_po-changed_at = utclong_now( ).

      " Add to update buffer
      APPEND ls_po TO lcl_buffer=>mt_update_po.

      " Set mapped
      APPEND VALUE #(
        %cid   = ls_entity-%cid
        po_id  = ls_entity-po_id
      ) TO mapped-po.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_po.
    DATA: ls_delete TYPE zpo_hdr.

    LOOP AT entities INTO DATA(ls_entity).
      " Prepare for logical delete
      ls_delete-mandt = sy-mandt.
      ls_delete-po_id = ls_entity-po_id.

      " Add to delete buffer (will be processed as logical delete in saver)
      APPEND ls_delete TO lcl_buffer=>mt_delete_po.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_po.
    DATA: lt_result TYPE TABLE OF zi_po,
          lv_idx    TYPE i.

    " Read from CDS view (which filters IS_DELETED = ' ')
    SELECT *
      FROM zi_po
      WHERE mandt = @sy-mandt
        AND po_id IN @keys
      INTO TABLE @lt_result.

    IF sy-subrc = 0.
      LOOP AT keys INTO DATA(ls_key).
        lv_idx = sy-tabix.
        READ TABLE lt_result INTO DATA(ls_data)
          WITH KEY po_id = ls_key-po_id.
        IF sy-subrc = 0.
          APPEND CORRESPONDING #( ls_data ) TO result INDEX lv_idx.
        ELSE.
          APPEND INITIAL LINE TO result INDEX lv_idx.
        ENDIF.
      ENDLOOP.
    ELSE.
      LOOP AT keys INTO ls_key.
        APPEND INITIAL LINE TO result.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD create_items.
    DATA: ls_item      TYPE zpo_itm,
          lv_po_exists TYPE xsdboolean.

    LOOP AT entities INTO DATA(ls_entity).
      " Check if parent PO exists
      SELECT SINGLE @abap_true INTO lv_po_exists
        FROM zpo_hdr
        WHERE mandt = @sy-mandt
          AND po_id = @ls_entity-po_id
          AND is_deleted = ' '.

      IF lv_po_exists IS NOT TRUE.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '004'
                              v1 = ls_entity-po_id )
        ) TO reported-po_item.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po_item.
        CONTINUE.
      ENDIF.

      " Validate item number
      IF ls_entity-item_no IS INITIAL.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '005'
                              v1 = 'ITEM_NO' )
        ) TO reported-po_item.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po_item.
        CONTINUE.
      ENDIF.

      " Prepare item for insert
      ls_item = CORRESPONDING #( ls_entity ).
      ls_item-mandt      = sy-mandt.
      ls_item-is_deleted = ' '.
      ls_item-created_by = sy-uname.
      ls_item-created_at = utclong_now( ).
      ls_item-changed_by = sy-uname.
      ls_item-changed_at = utclong_now( ).

      " Add to create buffer
      APPEND ls_item TO lcl_buffer=>mt_create_item.

      " Set mapped
      APPEND VALUE #(
        %cid    = ls_entity-%cid
        po_id   = ls_entity-po_id
        item_no = ls_entity-item_no
      ) TO mapped-po_item.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_items.
    " Read items by association filtered by IS_DELETED = ' '
    SELECT *
      FROM zi_po_item
      WHERE mandt = @sy-mandt
        AND po_id IN @keys
      INTO TABLE @DATA(lt_items).

    LOOP AT keys INTO DATA(ls_key).
      LOOP AT lt_items INTO DATA(ls_item)
        WHERE po_id = ls_key-po_id.
        APPEND CORRESPONDING #( ls_item ) TO result
          ASSIGNING FIELD-SYMBOL(<fs_result>).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock_po.
    " Lock master handling - framework handles locking via lock object
    " For unmanaged RAP, the lock mechanism is simplified
    " In production, a lock object EZPO_HDR should be created
  ENDMETHOD.

  METHOD global_authorization.
    " Global authorization - trivially grant all operations for demo
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_po_item IMPLEMENTATION.

  METHOD update_item.
    DATA: ls_item TYPE zpo_itm,
          lv_cnt  TYPE i.

    LOOP AT entities INTO DATA(ls_entity).
      " Check if item exists and not deleted
      SELECT SINGLE @abap_true INTO DATA(lv_exists)
        FROM zpo_itm
        WHERE mandt    = @sy-mandt
          AND po_id    = @ls_entity-po_id
          AND item_no  = @ls_entity-item_no
          AND is_deleted = ' '.

      IF lv_exists IS NOT TRUE.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '006'
                              v1 = ls_entity-item_no )
        ) TO reported-po_item.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po_item.
        CONTINUE.
      ENDIF.

      " Prepare for update
      ls_item = CORRESPONDING #( ls_entity ).
      ls_item-mandt      = sy-mandt.
      ls_item-changed_by = sy-uname.
      ls_item-changed_at = utclong_now( ).

      " Add to update buffer
      APPEND ls_item TO lcl_buffer=>mt_update_item.

      " Set mapped
      APPEND VALUE #(
        %cid    = ls_entity-%cid
        po_id   = ls_entity-po_id
        item_no = ls_entity-item_no
      ) TO mapped-po_item.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_item.
    DATA: ls_delete TYPE zpo_itm.

    LOOP AT entities INTO DATA(ls_entity).
      " Prepare for logical delete
      ls_delete-mandt   = sy-mandt.
      ls_delete-po_id   = ls_entity-po_id.
      ls_delete-item_no = ls_entity-item_no.

      " Add to delete buffer
      APPEND ls_delete TO lcl_buffer=>mt_delete_item.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_item.
    DATA: lt_result TYPE TABLE OF zi_po_item,
          lv_idx    TYPE i.

    " Read from CDS view (which filters IS_DELETED = ' ')
    SELECT *
      FROM zi_po_item
      WHERE mandt   = @sy-mandt
        AND po_id   = @keys-po_id
        AND item_no = @keys-item_no
      INTO TABLE @lt_result.

    IF sy-subrc = 0.
      LOOP AT keys INTO DATA(ls_key).
        lv_idx = sy-tabix.
        READ TABLE lt_result INTO DATA(ls_data)
          WITH KEY po_id = ls_key-po_id
                   item_no = ls_key-item_no.
        IF sy-subrc = 0.
          APPEND CORRESPONDING #( ls_data ) TO result INDEX lv_idx.
        ELSE.
          APPEND INITIAL LINE TO result INDEX lv_idx.
        ENDIF.
      ENDLOOP.
    ELSE.
      LOOP AT keys INTO ls_key.
        APPEND INITIAL LINE TO result.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_po IMPLEMENTATION.

  METHOD save_modified.
    DATA: lv_po_id TYPE zpo_hdr-po_id.

    " Process creates
    IF lcl_buffer=>mt_create_po IS NOT INITIAL.
      INSERT zpo_hdr FROM TABLE @lcl_buffer=>mt_create_po.
    ENDIF.

    " Process item creates
    IF lcl_buffer=>mt_create_item IS NOT INITIAL.
      INSERT zpo_itm FROM TABLE @lcl_buffer=>mt_create_item.
    ENDIF.

    " Process PO updates
    IF lcl_buffer=>mt_update_po IS NOT INITIAL.
      LOOP AT lcl_buffer=>mt_update_po INTO DATA(ls_po_upd).
        UPDATE zpo_hdr SET
          vendor_id  = @ls_po_upd-vendor_id,
          doc_date   = @ls_po_upd-doc_date,
          currency   = @ls_po_upd-currency,
          status     = @ls_po_upd-status,
          changed_by = @ls_po_upd-changed_by,
          changed_at = @ls_po_upd-changed_at
          WHERE mandt = @sy-mandt
            AND po_id = @ls_po_upd-po_id.
      ENDLOOP.
    ENDIF.

    " Process item updates
    IF lcl_buffer=>mt_update_item IS NOT INITIAL.
      LOOP AT lcl_buffer=>mt_update_item INTO DATA(ls_itm_upd).
        UPDATE zpo_itm SET
          material   = @ls_itm_upd-material,
          quantity   = @ls_itm_upd-quantity,
          uom        = @ls_itm_upd-uom,
          net_price  = @ls_itm_upd-net_price,
          currency   = @ls_itm_upd-currency,
          plant      = @ls_itm_upd-plant,
          changed_by = @ls_itm_upd-changed_by,
          changed_at = @ls_itm_upd-changed_at
          WHERE mandt   = @sy-mandt
            AND po_id   = @ls_itm_upd-po_id
            AND item_no = @ls_itm_upd-item_no.
      ENDLOOP.
    ENDIF.

    " Process logical PO deletes (cascade to items)
    IF lcl_buffer=>mt_delete_po IS NOT INITIAL.
      LOOP AT lcl_buffer=>mt_delete_po INTO DATA(ls_po_del).
        " Set PO as logically deleted
        UPDATE zpo_hdr SET is_deleted = @abap_true
          WHERE mandt = @sy-mandt
            AND po_id = @ls_po_del-po_id.

        " Cascade: Set all items of this PO as logically deleted
        UPDATE zpo_itm SET is_deleted = @abap_true
          WHERE mandt = @sy-mandt
            AND po_id = @ls_po_del-po_id.
      ENDLOOP.
    ENDIF.

    " Process logical item deletes
    IF lcl_buffer=>mt_delete_item IS NOT INITIAL.
      LOOP AT lcl_buffer=>mt_delete_item INTO DATA(ls_itm_del).
        UPDATE zpo_itm SET is_deleted = @abap_true
          WHERE mandt   = @sy-mandt
            AND po_id   = @ls_itm_del-po_id
            AND item_no = @ls_itm_del-item_no.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD finalize.
    lcl_buffer=>clear_all( ).
  ENDMETHOD.

ENDCLASS.