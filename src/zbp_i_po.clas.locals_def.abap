"! Transaction buffer for PO operations
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    " Buffer tables
    CLASS-DATA:
      mt_create_po   TYPE TABLE OF zpo_hdr,
      mt_update_po   TYPE TABLE OF zpo_hdr,
      mt_delete_po   TYPE TABLE OF zpo_hdr,
      mt_create_item TYPE TABLE OF zpo_itm,
      mt_update_item TYPE TABLE OF zpo_itm,
      mt_delete_item TYPE TABLE OF zpo_itm.
    
    " Methods
    CLASS-METHODS:
      initialize,
      clear_all.
ENDCLASS.

"! Root entity handler for PO
CLASS lhc_po DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      create_po FOR MODIFY
        IMPORTING entities FOR CREATE zi_po,
      update_po FOR MODIFY
        IMPORTING entities FOR UPDATE zi_po,
      delete_po FOR MODIFY
        IMPORTING entities FOR DELETE zi_po,
      read_po FOR READ
        IMPORTING keys FOR READ zi_po
        RESULT result,
      create_items FOR MODIFY
        IMPORTING entities FOR CREATE zi_po\_Items,
      rba_items FOR READ
        IMPORTING keys_for_tabname FOR READ zi_po\_Items
        FULL result_failed,
      lock_po FOR LOCK
        IMPORTING keys FOR LOCK zi_po,
      global_authorization FOR AUTHORIZATION
        IMPORTING request FOR GLOBAL AUTHORIZATION zi_po
        RESULT result.
ENDCLASS.

"! Child entity handler for PO Item
CLASS lhc_po_item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      update_item FOR MODIFY
        IMPORTING entities FOR UPDATE zi_po_item,
      delete_item FOR MODIFY
        IMPORTING entities FOR DELETE zi_po_item,
      read_item FOR READ
        IMPORTING keys FOR READ zi_po_item
        RESULT result.
ENDCLASS.

"! Saver class for PO operations
CLASS lsc_po DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PRIVATE SECTION.
    METHODS:
      save_modified REDEFINITION,
      finalize REDEFINITION.
ENDCLASS.