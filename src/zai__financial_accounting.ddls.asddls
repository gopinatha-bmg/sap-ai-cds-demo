@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.sqlViewName: 'ZC_DUPVINV365'
@EndUserText.label: 'Duplicate vendor invoices in last 365 days'
define view ZC_DupVendorInvoice365
  as select distinct from bkpf as h
    inner join bseg as i
      on  i.mandt = h.mandt
      and i.bukrs = h.bukrs
      and i.belnr = h.belnr
      and i.gjahr = h.gjahr
    inner join lfa1 as v
      on  v.mandt = i.mandt
      and v.lifnr = i.lifnr
    inner join bkpf as h2
      on  h2.mandt = h.mandt
      and h2.budat >= add_days( $session.system_date, -365 )
      and h2.bstat = ''
      and h2.xblnr = h.xblnr
      and h2.bldat = h.bldat
    inner join bseg as i2
      on  i2.mandt = h2.mandt
      and i2.bukrs = h2.bukrs
      and i2.belnr = h2.belnr
      and i2.gjahr = h2.gjahr
      and i2.lifnr = i.lifnr
      and i2.wrbtr = i.wrbtr
      and (
             h2.bukrs <> h.bukrs
          or h2.belnr <> h.belnr
          or h2.gjahr <> h.gjahr
          or i2.buzei <> i.buzei
          )
{
  key h.bukrs                            as CompanyCode,
  key h.belnr                            as AccountingDocument,
  key h.gjahr                            as FiscalYear,
      h.budat                            as PostingDate,
      h.bldat                            as DocumentDate,
      h.blart                            as DocumentType,
      h.xblnr                            as ReferenceDocument,
      i.lifnr                            as Vendor,
      v.name1                            as VendorName,
      i.wrbtr                            as AmountInDocumentCurrency,
      i.dmbtr                            as AmountInCompanyCodeCurrency,
      i.waers                            as DocumentCurrency,
      cast( 'X' as abap.char(1) )        as DuplicateFlag
}
where
      h.budat >= add_days( $session.system_date, -365 )
  and h.bstat = ''
  and i.lifnr <> ''
  and i.wrbtr > 0
  // TODO: confirm that BKPF-XBLNR is the intended invoice reference in this client.
  // TODO: confirm that BKPF-BLDAT is the intended invoice date in this client.
  // TODO: for stronger posting semantics, consider restricting BKPF-BLART per company policy
  //       or modeling a base document-level amount view instead of line-item WRBTR matching.