@EndUserText.label: 'Purchase Order Header - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName:       'Purchase Order',
  typeNamePlural: 'Purchase Orders',
  title:          { type: #STANDARD, value: 'PoId' },
  description:    { type: #STANDARD, value: 'Supplier' }
}
define root view entity ZC_PO_RAP_H
  provider contract transactional_ui
  as projection on ZI_PO_RAP_H
{
      @UI.facet: [
        { id:            'GeneralInfo',
          purpose:       #STANDARD,
          type:          #IDENTIFICATION_REFERENCE,
          label:         'General Information',
          position:      10 },
        { id:            'ItemFacet',
          purpose:       #STANDARD,
          type:          #LINEITEM_REFERENCE,
          label:         'Purchase Order Items',
          position:      20,
          targetElement: '_Items' }
      ]

      @UI.lineItem:     [{ position: 10, importance: #HIGH }]
      @UI.identification: [{ position: 10 }]
  key PoId,

      @UI.lineItem:     [{ position: 20, importance: #MEDIUM }]
      @UI.identification: [{ position: 20 }]
      CompanyCode,

      @UI.lineItem:     [{ position: 30, importance: #HIGH }]
      @UI.identification: [{ position: 30 }]
      Supplier,

      @UI.lineItem:     [{ position: 40, importance: #MEDIUM }]
      @UI.identification: [{ position: 40 }]
      DocumentDate,

      @UI.identification: [{ position: 50 }]
      CurrencyCode,

      @UI.lineItem:     [{ position: 50, importance: #HIGH }]
      @UI.identification: [{ position: 60 }]
      GrossAmount,

      @UI.hidden: true
      CreatedBy,
      @UI.hidden: true
      CreatedAt,
      @UI.hidden: true
      LastChangedBy,
      @UI.hidden: true
      LastChangedAt,

      /* Composition - redirected to projection child */
      _Items : redirected to composition child ZC_PO_RAP_I
}