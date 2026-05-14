@OData.publish: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@AbapCatalog.sqlViewName: 'ZC_DUPVINV6D'
@EndUserText.label: 'Duplicate Vendor Invoice Documents by Posting Window'
define view ZC_DUPVINV6D
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
    inner join ZC_DVINVAGG(
      p_posting_date_from: $parameters.p_posting_date_from,
      p_posting_date_to:   $parameters.p_posting_date_to,
      p_company_code:      $parameters.p_company_code,
      p_fiscal_year:       $parameters.p_fiscal_year,
      p_amount_threshold:  $parameters.p_amount_threshold ) as dup
      on  dup.bukrs          = item.bukrs
      and dup.lifnr          = item.lifnr
      and dup.reference_doc  = head.xblnr
      and dup.waers          = item.waers
      and dup.wrbtr          = item.wrbtr
{
  key item.bukrs          as CompanyCode,
  key item.belnr          as AccountingDocument,
  key item.gjahr          as FiscalYear,
  key item.buzei          as AccountingDocumentItem,
      head.budat          as PostingDate,
      head.blart          as DocumentType,
      head.bldat          as DocumentDate,
      head.xblnr          as ReferenceDocument,
      item.lifnr          as Vendor,
      item.waers          as Currency,
      item.wrbtr          as AmountInDocumentCurrency,
      item.dmbtr          as AmountInCompanyCodeCurrency,
      item.shkzg          as DebitCreditCode,
      item.koart          as AccountType,
      item.hkont          as GLAccount,
      dup.duplicate_count as DuplicateOccurrenceCount
}
where head.budat >= $parameters.p_posting_date_from
  and head.budat <= $parameters.p_posting_date_to
  and head.bukrs = $parameters.p_company_code
  and head.gjahr = $parameters.p_fiscal_year
  and item.koart = 'K'
  and item.lifnr <> ''
  and head.xblnr <> ''
  and item.wrbtr >= $parameters.p_amount_threshold
;