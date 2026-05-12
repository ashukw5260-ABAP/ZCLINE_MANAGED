@EndUserText.label: 'PO Item Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_PO_ITEM
  as projection on ZI_PO_ITEM
{
  key mandt,
  key po_id,
  key item_no,
      material,
      quantity,
      uom,
      net_price,
      currency,
      plant,
      is_deleted,
      created_by,
      created_at,
      changed_by,
      changed_at,
      _PO: redirected to parent ZC_PO
}