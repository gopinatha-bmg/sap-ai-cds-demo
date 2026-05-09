@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.sqlViewName: 'ZC_DUPVINVYTD'
@EndUserText.label: 'Duplicate vendor invoices in current fiscal year to date'
define view ZC_DupVendorInvoiceYTD
  as select from
    (
      select from bkpf as h
        inner join bseg as i
          on  i.bukrs = h.bukrs
          and i.belnr = h.belnr
          and i.gjahr = h.gjahr
      {
        key h.bukrs                    as CompanyCode,
        key h.belnr                    as AccountingDocument,
        key h.gjahr                    as FiscalYear,
            max( h.budat )             as PostingDate,
            max( h.bldat )             as DocumentDate,
            max( h.blart )             as DocumentType,
            i.lifnr                    as Vendor,
            max( h.xblnr )             as ReferenceDocument,
            i.wrbtr                    as AmountInDocumentCurrency,
            max( i.dmbtr )             as AmountInCompanyCodeCurrency,
            max( i.waers )             as DocumentCurrency,
            max( i.shkzg )             as DebitCreditIndicator
      }
      where
            h.budat >= concat( cast( h.gjahr as abap.char(4) ), '0101' )
        and h.budat <= $session.system_date
        and i.lifnr <> ''
        and h.xblnr <> ''
        and i.wrbtr > 0
        // Approximation only: derives year start from BKPF-GJAHR as calendar YYYY0101.
        // If "fiscal year" must follow fiscal year variant, replace with a fiscal calendar mapping CDS/table.
        // Generic default only: this does not hard-code client-specific document types or payment methods.
      group by
            h.bukrs,
            h.belnr,
            h.gjahr,
            i.lifnr,
            i.wrbtr
    ) as doc
    inner join lfa1 as v
      on  v.lifnr = doc.Vendor
    inner join
    (
      select from
        (
          select from bkpf as h2
            inner join bseg as i2
              on  i2.bukrs = h2.bukrs
              and i2.belnr = h2.belnr
              and i2.gjahr = h2.gjahr
          {
            key h2.bukrs               as CompanyCode,
            key h2.belnr               as AccountingDocument,
            key h2.gjahr               as FiscalYear,
                i2.lifnr               as Vendor,
                h2.xblnr               as ReferenceDocument,
                h2.bldat               as InvoiceDate,
                i2.wrbtr               as AmountInDocumentCurrency
          }
          where
                h2.budat >= concat( cast( h2.gjahr as abap.char(4) ), '0101' )
            and h2.budat <= $session.system_date
            and i2.lifnr <> ''
            and h2.xblnr <> ''
            and i2.wrbtr > 0
          group by
                h2.bukrs,
                h2.belnr,
                h2.gjahr,
                i2.lifnr,
                h2.xblnr,
                h2.bldat,
                i2.wrbtr
        ) as base
      {
            base.Vendor                as Vendor,
            base.ReferenceDocument     as ReferenceDocument,
            base.InvoiceDate           as InvoiceDate,
            base.AmountInDocumentCurrency as AmountInDocumentCurrency,
            count( * )                 as DuplicateCount
      }
      group by
            base.Vendor,
            base.ReferenceDocument,
            base.InvoiceDate,
            base.AmountInDocumentCurrency
      having count( * ) > 1
    ) as dup
      on  dup.Vendor                   = doc.Vendor
      and dup.ReferenceDocument        = doc.ReferenceDocument
      and dup.InvoiceDate              = doc.DocumentDate
      and dup.AmountInDocumentCurrency = doc.AmountInDocumentCurrency
{
  key doc.CompanyCode                  as CompanyCode,
  key doc.AccountingDocument           as AccountingDocument,
  key doc.FiscalYear                   as FiscalYear,
      doc.PostingDate                  as PostingDate,
      doc.DocumentDate                 as DocumentDate,
      doc.DocumentType                 as DocumentType,
      doc.Vendor                       as Vendor,
      v.name1                          as VendorName,
      doc.ReferenceDocument            as ReferenceDocument,
      doc.AmountInDocumentCurrency     as AmountInDocumentCurrency,
      doc.AmountInCompanyCodeCurrency  as AmountInCompanyCodeCurrency,
      doc.DocumentCurrency             as DocumentCurrency,
      doc.DebitCreditIndicator         as DebitCreditIndicator,
      dup.DuplicateCount               as DuplicateCount
}