@AbapCatalog.sqlViewName: 'ZVDUPVINV90'
@EndUserText.label: 'Duplicate vendor invoice check'

define view Z_I_DuplicateVendorInvoice
  as select from bkpf as h
    inner join bseg as i
      on i.bukrs = h.bukrs
{
  key h.bukrs as CompanyCode,
  key h.belnr as AccountingDocument,
  key h.gjahr as FiscalYear,
      h.budat as PostingDate,
      i.wrbtr as Amount
}