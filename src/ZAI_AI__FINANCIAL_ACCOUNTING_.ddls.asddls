@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.sqlViewName: 'ZC_DUPVINV365'
@EndUserText.label: 'Duplicate vendor invoices in last 365 days'
define view ZC_DupVendorInvoice365
  as select from bkpf as h
    inner join bseg as i
      on  i.mandt = h.mandt
      and i.bukrs = h.bukrs
      and i.belnr = h.belnr
      and i.gjahr = h.gjahr
    inner join lfa1 as v
      on  v.mandt = i.mandt
      and v.lifnr = i.lifnr
{
  key h.bukrs                          as CompanyCode,
  key h.belnr                          as AccountingDocument,
  key h.gjahr                          as FiscalYear,
      h.bldat                          as DocumentDate,
      h.budat                          as PostingDate,
      h.blart                          as DocumentType,
      h.xblnr                          as ReferenceDocument,
      i.buzei                          as LineItem,
      i.lifnr                          as Vendor,
      v.name1                          as VendorName,
      i.wrbtr                          as AmountInDocumentCurrency,
      i.waers                          as DocumentCurrency
}
where
      h.budat >= add_days( $session.system_date, -365 )
  and h.bstat = ''
  and i.lifnr <> ''
  and i.koart = 'K'
  and i.shkzg = 'H'
  and i.wrbtr > 0
  and h.xblnr <> ''
  // Conservative default: duplicate logic uses header reference (BKPF-XBLNR),
  // document date (BKPF-BLDAT), vendor (BSEG-LIFNR), amount (BSEG-WRBTR),
  // and currency (BSEG-WAERS).
  // TODO: For production accuracy and document-level output grain, prefer a
  // layered design that derives one comparable vendor-invoice amount per document
  // and then detects duplicates via aggregation.
  // TODO: Consider restricting BKPF-BLART to vendor-invoice document types per policy.
  and exists (
    select from bkpf as h2
      inner join bseg as i2
        on  i2.mandt = h2.mandt
        and i2.bukrs = h2.bukrs
        and i2.belnr = h2.belnr
        and i2.gjahr = h2.gjahr
    {
      h2.belnr
    }
    where
          h2.mandt = h.mandt
      and h2.budat >= add_days( $session.system_date, -365 )
      and h2.bstat = ''
      and i2.lifnr = i.lifnr
      and i2.koart = 'K'
      and i2.shkzg = 'H'
      and i2.wrbtr = i.wrbtr
      and i2.waers = i.waers
      and h2.xblnr = h.xblnr
      and h2.bldat = h.bldat
      and (
            h2.bukrs <> h.bukrs
         or h2.belnr <> h.belnr
         or h2.gjahr <> h.gjahr
         or i2.buzei <> i.buzei
      )
  );