@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.sqlViewName: 'ZC_DUPVINV365'
@EndUserText.label: 'Duplicate vendor invoices in last 365 days'
define view ZC_DupVendorInvoice365
  as select distinct from bkpf as h
    inner join bseg as i
      on  i.bukrs = h.bukrs
      and i.belnr = h.belnr
      and i.gjahr = h.gjahr
    inner join lfa1 as v
      on  v.lifnr = i.lifnr
    inner join (
      select distinct from bkpf as h1
        inner join bseg as i1
          on  i1.bukrs = h1.bukrs
          and i1.belnr = h1.belnr
          and i1.gjahr = h1.gjahr
        inner join (
          select from (
            select distinct from bkpf as h2
              inner join bseg as i2
                on  i2.bukrs = h2.bukrs
                and i2.belnr = h2.belnr
                and i2.gjahr = h2.gjahr
            {
                  h2.bukrs                           as CompanyCode,
                  h2.belnr                           as AccountingDocument,
                  h2.gjahr                           as FiscalYear,
                  i2.lifnr                           as Vendor,
                  h2.xblnr                           as ReferenceDocumentNumber,
                  h2.bldat                           as DocumentDate,
                  i2.wrbtr                           as AmountInDocumentCurrency
            }
            where
                  h2.budat >= add_days( $session.system_date, -365 )
              and i2.lifnr is not null
              and h2.xblnr is not null
              and h2.xblnr <> ''
              and i2.wrbtr > 0
              // Heuristic only: vendor invoice candidates are identified by vendor line items with positive amount.
              // Consider refining in your system with document type / posting key / reversal logic if required.
          ) as docsig
          {
                docsig.Vendor                       as Vendor,
                docsig.ReferenceDocumentNumber      as ReferenceDocumentNumber,
                docsig.DocumentDate                 as DocumentDate,
                docsig.AmountInDocumentCurrency     as AmountInDocumentCurrency,
                count( * )                          as DuplicateCount
          }
          group by
                docsig.Vendor,
                docsig.ReferenceDocumentNumber,
                docsig.DocumentDate,
                docsig.AmountInDocumentCurrency
          having count( * ) > 1
        ) as dup
          on  dup.Vendor                   = i1.lifnr
          and dup.ReferenceDocumentNumber  = h1.xblnr
          and dup.DocumentDate             = h1.bldat
          and dup.AmountInDocumentCurrency = i1.wrbtr
      {
        h1.bukrs                           as CompanyCode,
        h1.belnr                           as AccountingDocument,
        h1.gjahr                           as FiscalYear,
        dup.DuplicateCount                 as DuplicateCount
      }
      where
            h1.budat >= add_days( $session.system_date, -365 )
        and i1.lifnr is not null
        and h1.xblnr is not null
        and h1.xblnr <> ''
        and i1.wrbtr > 0
    ) as dupdoc
      on  dupdoc.CompanyCode        = h.bukrs
      and dupdoc.AccountingDocument = h.belnr
      and dupdoc.FiscalYear         = h.gjahr
{
  key h.bukrs                              as CompanyCode,
  key h.belnr                              as AccountingDocument,
  key h.gjahr                              as FiscalYear,
      h.blart                              as DocumentType,
      h.bldat                              as DocumentDate,
      h.budat                              as PostingDate,
      h.xblnr                              as ReferenceDocumentNumber,
      i.lifnr                              as Vendor,
      v.name1                              as VendorName,
      i.wrbtr                              as AmountInDocumentCurrency,
      i.dmbtr                              as AmountInCompanyCodeCurrency,
      i.waers                              as DocumentCurrency,
      dupdoc.DuplicateCount                as DuplicateCount
}
where
      h.budat >= add_days( $session.system_date, -365 )
  and i.lifnr is not null
  and h.xblnr is not null
  and h.xblnr <> ''
  and i.wrbtr > 0
  // TODO: parameterize or configure optional company-code restriction instead of hard-coded literals.
;