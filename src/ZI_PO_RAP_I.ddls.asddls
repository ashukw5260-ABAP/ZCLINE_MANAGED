@EndUserText.label: 'Purchase Order Item - BO Interface View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.viewEnhancementCategory: [#NONE]
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #S,
  dataClass:      #MIXED
}
define view entity ZI_PO_RAP_I
  as select from zpo_rap_i
  association to parent ZI_PO_RAP_H as _Header
    on $projection.PoId = _Header.PoId
{
  key po_id           as PoId,
  key po_item         as PoItem,

      material        as Material,
      quantity        as Quantity,
      currency_code   as CurrencyCode,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      unit_price      as UnitPrice,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      net_amount      as NetAmount,

      created_by      as CreatedBy,
      created_at      as CreatedAt,
      last_changed_by as LastChangedBy,
      last_changed_at as LastChangedAt,

      /* Association to parent */
      _Header
}