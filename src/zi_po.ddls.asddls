@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Header Interface View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_PO
  as select from zpo_hdr
  composition [0..*] of ZI_PO_ITEM as _Items
{
  key mandt      as MANDT,
  key po_id      as PO_ID,
      vendor_id  as VENDOR_ID,
      doc_date   as DOC_DATE,
      currency   as CURRENCY,
      status     as STATUS,
      is_deleted as IS_DELETED,
      created_by as CREATED_BY,
      created_at as CREATED_AT,
      changed_by as CHANGED_BY,
      changed_at as CHANGED_AT,
      _Items
}
where
  is_deleted = ' '