@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Item Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PO_ITEM
  as select from zpo_itm
  association to parent ZI_PO as _PO on $projection.po_id = _PO.po_id
{
  key mandt      as MANDT,
  key po_id      as PO_ID,
  key item_no    as ITEM_NO,
      material   as MATERIAL,
      quantity   as QUANTITY,
      uom        as UOM,
      net_price  as NET_PRICE,
      currency   as CURRENCY,
      plant      as PLANT,
      is_deleted as IS_DELETED,
      created_by as CREATED_BY,
      created_at as CREATED_AT,
      changed_by as CHANGED_BY,
      changed_at as CHANGED_AT,
      _PO
}
where
  is_deleted = ' '