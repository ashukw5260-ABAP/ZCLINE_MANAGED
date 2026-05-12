@EndUserText.label: 'Purchase Order Header - BO Interface View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.viewEnhancementCategory: [#NONE]
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #S,
  dataClass:      #MIXED
}
define root view entity ZI_PO_RAP_H
  as select from zpo_rap_h
  composition [0..*] of ZI_PO_RAP_I as _Items
{
  key po_id           as PoId,

      company_code    as CompanyCode,
      supplier        as Supplier,
      document_date   as DocumentDate,
      currency_code   as CurrencyCode,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      gross_amount    as GrossAmount,

      created_by      as CreatedBy,
      created_at      as CreatedAt,
      last_changed_by as LastChangedBy,
      last_changed_at as LastChangedAt,

      /* Composition */
      _Items
}