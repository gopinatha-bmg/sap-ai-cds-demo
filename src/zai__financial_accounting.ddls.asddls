@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Duplicate vendor invoices in last 12 months'
define view entity zai__financial_accounting
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
  key h.bukrs                                    as CompanyCode,
  key h.belnr                                    as AccountingDocument,
  key h.gjahr                                    as FiscalYear,
      h.budat                                    as PostingDate,
      h.bldat                                    as DocumentDate,
      h.blart                                    as DocumentType,
      h.xblnr                                    as ReferenceDocumentNumber,
      i.lifnr                                    as Vendor,
      v.name1                                    as VendorName,
      i.wrbtr                                    as AmountInDocumentCurrency,
      i.dmbtr                                    as AmountInCompanyCodeCurrency,
      i.waers                                    as DocumentCurrency,
      cast( 'X' as abap.char(1) )                as DuplicateFlag
}
where
      h.budat >= add_days( $session.system_date, -365 )
  and i.lifnr <> ''
  and h.bstat = ''
  and h.blart in ( 'KR', 'RE' ) // TODO: client-specific example only; confirm invoice document types for this system
  and i.wrbtr > 0               // heuristic only; consider tightening with posting semantics if required
  and i.buzei = (
    select from bseg as i0
    {
      min( i0.buzei )
    }
    where
          i0.mandt = i.mandt
      and i0.bukrs = i.bukrs
      and i0.belnr = i.belnr
      and i0.gjahr = i.gjahr
      and i0.lifnr = i.lifnr
      and i0.wrbtr > 0
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
          h2.budat >= add_days( $session.system_date, -365 )
      and h2.bstat = ''
      and h2.blart in ( 'KR', 'RE' )
      and i2.lifnr = i.lifnr
      and i2.wrbtr > 0
      and i2.wrbtr = i.wrbtr
      and h2.xblnr = h.xblnr
      and h2.bldat = h.bldat
      and (
            h2.bukrs <> h.bukrs
         or h2.belnr <> h.belnr
         or h2.gjahr <> h.gjahr
      )
  )
// Assumption: duplicate logic uses vendor + reference number (BKPF-XBLNR) + invoice/document date (BKPF-BLDAT) + amount.
// This revision removes line-item projection and restricts to one vendor line per document to align better with document-level grain.
// For production-scale performance, prefer a layered CDS design: aggregate duplicate candidate groups first, then join back to BKPF/BSEG.
