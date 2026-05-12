@EndUserText.label: 'PO Header Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_PO
  provider contract transactional_query
  as projection on ZI_PO
{
  key mandt,
  key po_id,
      vendor_id,
      doc_date,
      currency,
      status,
      is_deleted,
      created_by,
      created_at,
      changed_by,
      changed_at,
      _Items: redirected to ZC_PO_ITEM
}