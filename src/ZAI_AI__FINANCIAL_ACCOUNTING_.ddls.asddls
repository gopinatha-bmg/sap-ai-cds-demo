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
    left outer join lfa1 as v
      on  v.mandt = i.mandt
      and v.lifnr = i.lifnr
{
  key h.bukrs                          as CompanyCode,
  key h.belnr                          as AccountingDocument,
  key h.gjahr                          as FiscalYear,
      h.budat                          as PostingDate,
      h.bldat                          as DocumentDate,
      h.blart                          as DocumentType,
      h.usnam                          as CreatedByUser,
      i.lifnr                          as Vendor,
      v.name1                          as VendorName,
      h.xblnr                          as InvoiceReference,
      i.wrbtr                          as AmountInDocumentCurrency,
      i.dmbtr                          as AmountInCompanyCodeCurrency,
      i.waers                          as DocumentCurrency
}
where
      h.budat >= add_days( $session.system_date, -365 )
  and i.lifnr is not null
  // TODO: confirm whether BKPF-XBLNR is the intended invoice reference for your process.
  and h.xblnr is not null
  and h.xblnr <> ''
  // Restrict to one representative vendor line per accounting document to keep document grain.
  and not exists (
    select from bseg as iprev
    {
      iprev.buzei
    }
    where
          iprev.mandt = i.mandt
      and iprev.bukrs = i.bukrs
      and iprev.belnr = i.belnr
      and iprev.gjahr = i.gjahr
      and iprev.lifnr = i.lifnr
      and iprev.buzei < i.buzei
  )
  // Duplicate rule at document level: same vendor/reference/document date/amount within the time window.
  and exists (
    select from bseg as i2
      inner join bkpf as h2
        on  h2.mandt = i2.mandt
        and h2.bukrs = i2.bukrs
        and h2.belnr = i2.belnr
        and h2.gjahr = i2.gjahr
    {
      i2.belnr
    }
    where
          i2.mandt = i.mandt
      and i2.lifnr = i.lifnr
      and h2.xblnr = h.xblnr
      and h2.bldat = h.bldat
      and i2.wrbtr = i.wrbtr
      and h2.budat >= add_days( $session.system_date, -365 )
      and (
             i2.bukrs <> i.bukrs
          or i2.belnr <> i.belnr
          or i2.gjahr <> i.gjahr
      )
  );