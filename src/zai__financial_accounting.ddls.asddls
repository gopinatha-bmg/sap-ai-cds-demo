@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.sqlViewName: 'ZC_DUPVINV90D'
@EndUserText.label: 'Duplicate vendor invoice documents in last 90 days'
define view ZC_DupVendorInvoice90D
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
  key h.bukrs                              as CompanyCode,
  key h.belnr                              as AccountingDocument,
  key h.gjahr                              as FiscalYear,
      h.budat                              as PostingDate,
      h.bldat                              as DocumentDate,
      h.blart                              as DocumentType,
      h.usnam                              as EnteredBy,
      i.lifnr                              as Vendor,
      v.name1                              as VendorName,
      i.xblnr                              as InvoiceReference,
      i.wrbtr                              as AmountInDocumentCurrency,
      i.dmbtr                              as AmountInCompanyCodeCurrency,
      i.waers                              as DocumentCurrency,
      i.shkzg                              as DebitCreditCode
}
where
      h.budat >= add_days( $session.system_date, -90 )
  and i.lifnr <> ''
  and i.wrbtr > 0
  and exists (
    select from bseg as d
      inner join bkpf as dh
        on  dh.mandt = d.mandt
        and dh.bukrs = d.bukrs
        and dh.belnr = d.belnr
        and dh.gjahr = d.gjahr
    {
      d.belnr
    }
    where
          d.mandt = i.mandt
      and d.lifnr = i.lifnr
      and d.xblnr = i.xblnr
      and dh.bldat = h.bldat
      and d.wrbtr = i.wrbtr
      and d.wrbtr > 0
      and dh.budat >= add_days( $session.system_date, -90 )
      and not (
            d.bukrs = i.bukrs
        and d.belnr = i.belnr
        and d.gjahr = i.gjahr
      )
  )
// Conservative assumptions:
// 1) Duplicate match uses vendor + invoice reference (BSEG-XBLNR) + document date (BKPF-BLDAT) + amount.
//    If your process stores the supplier invoice date in another standard/custom field, replace BLDAT accordingly.
// 2) Output is one row per accounting document, aligned to the requested grain; line item is intentionally excluded.
// 3) LFA1 join is retained only for VendorName display; remove it in a performance-focused base view if not needed.
// 4) No company-code restriction was provided; add an org filter if needed for performance/governance.
;