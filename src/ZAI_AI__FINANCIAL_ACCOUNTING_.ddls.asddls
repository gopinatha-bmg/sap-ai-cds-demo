@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.sqlViewName: 'ZC_DUPVINV12M'
@EndUserText.label: 'Duplicate vendor invoices in last 12 months'
define view ZC_DupVendorInvoice12M
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
  key h.bukrs                                as CompanyCode,
  key h.belnr                                as AccountingDocument,
  key h.gjahr                                as FiscalYear,
      h.blart                                as DocumentType,
      h.bldat                                as DocumentDate,
      h.budat                                as PostingDate,
      h.xblnr                                as ReferenceDocument,
      i.lifnr                                as Vendor,
      v.name1                                as VendorName,
      i.wrbtr                                as AmountInDocumentCurrency,
      i.dmbtr                                as AmountInCompanyCodeCurrency,
      i.shkzg                                as DebitCreditCode,
      i.waers                                as DocumentCurrency
}
where
      h.budat >= add_days( $session.system_date, -365 ) // TODO: replace with add_months(...,-12) if supported; 365 days is an approximation
  and h.bstat = ''
  // TODO: confirm whether restricting to direct FI postings only is intended; AWTYP = '' can exclude valid invoice origins
  and h.awtyp = ''
  // Approximation only: vendor-related FI items, not a definitive invoice-posting classifier.
  and i.lifnr <> ''
  and i.koart = 'K'
  and i.wrbtr > 0
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
      and h2.budat >= add_days( $session.system_date, -365 ) // TODO: replace with add_months(...,-12) if supported
      and h2.bstat = ''
      and h2.awtyp = ''
      and i2.koart = 'K'
      and i2.lifnr = i.lifnr
      and h2.xblnr = h.xblnr
      and h2.bldat = h.bldat
      and i2.wrbtr = i.wrbtr
      and i2.wrbtr > 0
      and (
             h2.bukrs <> h.bukrs
          or h2.belnr <> h.belnr
          or h2.gjahr <> h.gjahr
      )
  );