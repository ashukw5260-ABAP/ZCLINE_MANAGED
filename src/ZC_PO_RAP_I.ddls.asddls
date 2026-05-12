@EndUserText.label: 'Purchase Order Item - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName:       'Purchase Order Item',
  typeNamePlural: 'Purchase Order Items',
  title:          { type: #STANDARD, value: 'PoItem' },
  description:    { type: #STANDARD, value: 'Material' }
}
define view entity ZC_PO_RAP_I
  provider contract transactional_ui
  as projection on ZI_PO_RAP_I
{
      @UI.lineItem:     [{ position: 10, importance: #HIGH }]
      @UI.identification: [{ position: 10 }]
  key PoId,

      @UI.lineItem:     [{ position: 20, importance: #HIGH }]
      @UI.identification: [{ position: 20 }]
  key PoItem,

      @UI.lineItem:     [{ position: 30, importance: #HIGH }]
      @UI.identification: [{ position: 30 }]
      Material,

      @UI.lineItem:     [{ position: 40, importance: #MEDIUM }]
      @UI.identification: [{ position: 40 }]
      Quantity,

      @UI.identification: [{ position: 50 }]
      CurrencyCode,

      @UI.lineItem:     [{ position: 50, importance: #HIGH }]
      @UI.identification: [{ position: 60 }]
      UnitPrice,

      @UI.lineItem:     [{ position: 60, importance: #HIGH }]
      @UI.identification: [{ position: 70 }]
      NetAmount,

      @UI.hidden: true
      CreatedBy,
      @UI.hidden: true
      CreatedAt,
      @UI.hidden: true
      LastChangedBy,
      @UI.hidden: true
      LastChangedAt,

      /* Association to parent - redirected to projection root */
      _Header : redirected to parent ZC_PO_RAP_H
}