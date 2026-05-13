@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.sqlViewName: 'ZC_DUPVNDINV'
@EndUserText.label: 'Duplicate vendor invoice line items by reference/amount'
define view entity ZC_DupVendorInvoiceLine
  with parameters
    @EndUserText.label: 'Posting Date From'
    p_posting_date_from : abap.dats,
    @EndUserText.label: 'Posting Date To'
    p_posting_date_to   : abap.dats,
    @EndUserText.label: 'Company Code'
    p_company_code      : bukrs,
    @EndUserText.label: 'Fiscal Year'
    p_fiscal_year       : gjahr,
    @EndUserText.label: 'Amount Threshold'
    p_amount_threshold  : abap.dec( 15, 2 )
  as select from bseg as item
    inner join bkpf as head
      on  head.bukrs = item.bukrs
      and head.belnr = item.belnr
      and head.gjahr = item.gjahr
    inner join rbkp as invh
      on  invh.bukrs = head.bukrs
      and invh.belnr = head.belnr
      and invh.gjahr = head.gjahr
{
  key item.bukrs                    as CompanyCode,
  key item.belnr                    as AccountingDocument,
  key item.gjahr                    as FiscalYear,
  key item.buzei                    as AccountingDocumentItem,

      head.budat                    as PostingDate,
      head.bldat                    as DocumentDate,
      head.blart                    as DocumentType,
      head.waers                    as Currency,
      item.lifnr                    as Vendor,
      head.xblnr                    as ReferenceDocument,
      invh.rmwwr                    as GrossInvoiceAmount,
      invh.bldat                    as InvoiceDocumentDate,
      invh.xblnr                    as InvoiceReference,
      cast( 'DUPLICATE_VENDOR_INVOICE' as abap.char( 30 ) ) as ExceptionCode

}
where head.budat between :p_posting_date_from and :p_posting_date_to
  and item.bukrs = :p_company_code
  and item.gjahr = :p_fiscal_year
  and item.lifnr <> ''
  and head.xblnr <> ''
  and invh.rmwwr >= :p_amount_threshold
  and exists (
        select from bseg as item2
          inner join bkpf as head2
            on  head2.bukrs = item2.bukrs
            and head2.belnr = item2.belnr
            and head2.gjahr = item2.gjahr
          inner join rbkp as invh2
            on  invh2.bukrs = head2.bukrs
            and invh2.belnr = head2.belnr
            and invh2.gjahr = head2.gjahr
        {
          item2.belnr
        }
        where head2.budat between :p_posting_date_from and :p_posting_date_to
          and item2.bukrs = item.bukrs
          and item2.gjahr = :p_fiscal_year
          and item2.lifnr = item.lifnr
          and head2.xblnr = head.xblnr
          and head2.waers = head.waers
          and invh2.rmwwr = invh.rmwwr
          and (
                item2.belnr <> item.belnr
             or item2.gjahr <> item.gjahr
              )
      )