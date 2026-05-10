@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.sqlViewName: 'ZC_DUPVINV2Y'
@EndUserText.label: 'Duplicate vendor invoices in current and prior fiscal year'
define view ZC_DupVendorInvoice2Y
  as select distinct from bkpf as h
    inner join bseg as i
      on  i.mandt = h.mandt
      and i.bukrs = h.bukrs
      and i.belnr = h.belnr
      and i.gjahr = h.gjahr
    inner join lfa1 as v
      on  v.mandt = i.mandt
      and v.lifnr = i.lifnr
{
  key h.bukrs                         as CompanyCode,
  key h.belnr                         as AccountingDocument,
  key h.gjahr                         as FiscalYear,
      h.budat                         as PostingDate,
      h.bldat                         as DocumentDate,
      h.blart                         as DocumentType,
      h.xblnr                         as ReferenceDocument,
      i.lifnr                         as Vendor,
      v.name1                         as VendorName,
      i.wrbtr                         as AmountInDocumentCurrency,
      i.dmbtr                         as AmountInCompanyCodeCurrency,
      i.waers                         as DocumentCurrency,
      h.usnam                         as EnteredByUser
}
where
      i.lifnr <> ''
  and h.gjahr >= cast( substring( cast( add_days( $session.system_date, -366 ) as abap.char(8) ), 1, 4 ) as abap.numc(4) )
  and h.gjahr <= cast( substring( cast( $session.system_date as abap.char(8) ), 1, 4 ) as abap.numc(4) )
  and i.wrbtr > 0
  and h.xblnr <> ''
  // TODO: "vendor invoice" is approximated by presence of vendor line item and positive amount.
  // For productive use, consider restricting by configured invoice document types (BKPF-BLART),
  // excluding special G/L / non-invoice postings, or using a business mapping table.
  and exists (
    select from bkpf as h2
      inner join bseg as i2
        on  i2.mandt = h2.mandt
        and i2.bukrs = h2.bukrs
        and i2.belnr = h2.belnr
        and i2.gjahr = h2.gjahr
    fields h2.belnr
    where
          i2.mandt = i.mandt
      and i2.lifnr = i.lifnr
      and h2.xblnr = h.xblnr
      and h2.bldat = h.bldat
      and i2.wrbtr = i.wrbtr
      and h2.gjahr >= cast( substring( cast( add_days( $session.system_date, -366 ) as abap.char(8) ), 1, 4 ) as abap.numc(4) )
      and h2.gjahr <= cast( substring( cast( $session.system_date as abap.char(8) ), 1, 4 ) as abap.numc(4) )
      and (
             h2.bukrs <> h.bukrs
          or h2.belnr <> h.belnr
          or h2.gjahr <> h.gjahr
      )
  );