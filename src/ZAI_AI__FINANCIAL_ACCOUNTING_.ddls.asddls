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
      i.shkzg                         as DebitCreditCode,
      cast( 'X' as abap.char(1) )     as DuplicateFlag
}
where
      h.bukrs in ( '1000', '2000' )
  and h.budat >= add_days( $session.system_date, -365 )
  and h.budat <= $session.system_date
  and h.bstat = ''
  and i.lifnr <> ''
  and h.xblnr <> ''
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
      and (
             iprev.buzei < i.buzei
          )
  )
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
          h2.bukrs = h.bukrs
      and h2.budat >= add_days( $session.system_date, -365 )
      and h2.budat <= $session.system_date
      and h2.bstat = ''
      and i2.lifnr = i.lifnr
      and h2.xblnr = h.xblnr
      and h2.bldat = h.bldat
      and i2.wrbtr = i.wrbtr
      and i2.waers = i.waers
      and not exists (
        select from bseg as i2prev
        {
          i2prev.buzei
        }
        where
              i2prev.mandt = i2.mandt
          and i2prev.bukrs = i2.bukrs
          and i2prev.belnr = i2.belnr
          and i2prev.gjahr = i2.gjahr
          and i2prev.lifnr = i2.lifnr
          and (
                 i2prev.buzei < i2.buzei
              )
      )
      and (
             h2.belnr <> h.belnr
          or h2.gjahr <> h.gjahr
          )
  )
// Conservative assumptions:
// - Duplicate logic uses vendor + BKPF-XBLNR (invoice reference) + BKPF-BLDAT (invoice date) + BSEG-WRBTR/WAERS (amount/currency).
// - Restricted to company codes 1000 and 2000 and posting date within last 365 days.
// - Output is one row per accounting document by keeping only the first vendor line (lowest BUZEI) per document.
// - TODO: If your posting model can contain multiple vendor lines per invoice document, replace this heuristic with a layered base CDS
//         that derives one canonical vendor/amount tuple per document before duplicate detection.
// - TODO: If needed, further narrow by invoice-relevant BKPF-BLART values to reduce false positives.
;