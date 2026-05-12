CLASS ztcl_po_rap_test DEFINITION
  PUBLIC
  FINAL
  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS:
      test_create FOR TESTING,
      test_read FOR TESTING,
      test_update_item FOR TESTING,
      test_delete_item FOR TESTING,
      test_delete_po FOR TESTING.
ENDCLASS.

CLASS ztcl_po_rap_test IMPLEMENTATION.

  METHOD test_create.
    " Test: Create PO with 2 items
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE FIELDS ( po_id vendor_id doc_date currency status )
        WITH VALUE #( (
          %cid      = 'PO1'
          po_id     = 'PO0000001'
          vendor_id = 'VENDOR01'
          doc_date  = sy-datum
          currency  = 'USD'
          status    = 'O'
        ) )
      ENTITY po
        CREATE BY \_items
          FIELDS ( item_no material quantity uom net_price currency plant )
          WITH VALUE #( (
            %cid_ref = 'PO1'
            %target = VALUE #(
              (
                %cid     = 'ITEM1'
                item_no  = '00010'
                material = 'MAT001'
                quantity = '5.000'
                uom      = 'EA'
                net_price = '10.00'
                currency = 'USD'
                plant    = '1000'
              )
              (
                %cid     = 'ITEM2'
                item_no  = '00020'
                material = 'MAT002'
                quantity = '3.000'
                uom      = 'EA'
                net_price = '20.00'
                currency = 'USD'
                plant    = '1000'
              )
            )
          ) )
      REPORTED DATA(ls_create_reported)
      FAILED DATA(ls_create_failed)
      MAPPED DATA(ls_create_mapped).

    COMMIT ENTITIES.

    " Assert no failures
    cl_abap_unit_assert=>assert_initial(
      act = ls_create_failed
      msg = 'Create failed'
    ).
  ENDMETHOD.

  METHOD test_read.
    " Test: Read PO and verify 2 items returned
    READ ENTITIES OF zi_po
      ENTITY po
        BY \_items
          FIELDS ( po_id item_no material quantity )
          WITH VALUE #( ( po_id = 'PO0000001' ) )
      RESULT DATA(lt_items).

    " Assert 2 items found
    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lines( lt_items )
      msg = 'Expected 2 items'
    ).
  ENDMETHOD.

  METHOD test_update_item.
    " Test: Update item quantity
    MODIFY ENTITIES OF zi_po
      ENTITY po_item
        UPDATE FIELDS ( quantity )
        WITH VALUE #( (
          po_id   = 'PO0000001'
          item_no = '00010'
          quantity = '10.000'
        ) )
      REPORTED DATA(ls_upd_reported)
      FAILED DATA(ls_upd_failed).

    COMMIT ENTITIES.

    " Assert no failures
    cl_abap_unit_assert=>assert_initial(
      act = ls_upd_failed
      msg = 'Update failed'
    ).

    " Read and verify quantity
    READ ENTITIES OF zi_po
      ENTITY po_item
        FIELDS ( quantity )
        WITH VALUE #( (
          po_id   = 'PO0000001'
          item_no = '00010'
        ) )
      RESULT DATA(lt_read).

    IF NOT lt_read IS INITIAL.
      cl_abap_unit_assert=>assert_equals(
        exp = '10.000'
        act = lt_read[ 1 ]-quantity
        msg = 'Quantity not updated'
      ).
    ENDIF.
  ENDMETHOD.

  METHOD test_delete_item.
    " Test: Logical delete item 00020
    MODIFY ENTITIES OF zi_po
      ENTITY po_item
        DELETE WITH VALUE #( (
          po_id   = 'PO0000001'
          item_no = '00020'
        ) )
      REPORTED DATA(ls_del_reported)
      FAILED DATA(ls_del_failed).

    COMMIT ENTITIES.

    " Assert no failures
    cl_abap_unit_assert=>assert_initial(
      act = ls_del_failed
      msg = 'Delete item failed'
    ).

    " Read items and verify only 1 item remaining
    READ ENTITIES OF zi_po
      ENTITY po
        BY \_items
          FIELDS ( item_no )
          WITH VALUE #( ( po_id = 'PO0000001' ) )
      RESULT DATA(lt_remaining).

    " After logical delete, item 00020 should not appear
    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( lt_remaining )
      msg = 'Expected 1 item after delete'
    ).
  ENDMETHOD.

  METHOD test_delete_po.
    " Test: Logical delete PO (cascade to items)
    MODIFY ENTITIES OF zi_po
      ENTITY po
        DELETE WITH VALUE #( (
          po_id = 'PO0000001'
        ) )
      REPORTED DATA(ls_po_del_reported)
      FAILED DATA(ls_po_del_failed).

    COMMIT ENTITIES.

    " Assert no failures
    cl_abap_unit_assert=>assert_initial(
      act = ls_po_del_failed
      msg = 'Delete PO failed'
    ).

    " Read PO and verify not found
    READ ENTITIES OF zi_po
      ENTITY po
        FIELDS ( po_id )
        WITH VALUE #( ( po_id = 'PO0000001' ) )
      RESULT DATA(lt_po).

    " After logical delete, PO should not appear in results
    cl_abap_unit_assert=>assert_initial(
      act = lt_po
      msg = 'PO should not be found after delete'
    ).
  ENDMETHOD.

ENDCLASS.