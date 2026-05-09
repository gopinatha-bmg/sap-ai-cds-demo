@AbapCatalog.sqlViewName: 'ZVDUPVINVEX'
@EndUserText.label: 'Duplicate vendor invoices'
define view Z_I_DuplicateVendorInvoices
  as select from rbkp as inv
    inner join lfa1 as ven
      on ven.lifnr = inv.lifnr
{
  key inv.bukrs      as CompanyCode,
  key inv.lifnr      as Vendor,
  key inv.xblnr      as ReferenceDocumentNumber,
  key inv.bldat      as InvoiceDate,
  key inv.rmwwr      as InvoiceAmount,
  key inv.waers      as Currency,
  key inv.belnr      as InvoiceDocumentNumber,
  key inv.gjahr      as FiscalYear,

      inv.budat      as PostingDate,
      inv.blart      as DocumentType,
      inv.usnam      as EnteredByUser,
      ven.name1      as VendorName

}
where
      inv.bukrs in ( '1000', '2000' )
  and inv.budat >= add_days( $session.system_date, -180 )
  and inv.rmwwr >= 1000
  and inv.stblg = ''          // exclude reversed documents
  and inv.rbstat = '5'        // TODO: verify/document RBKP status value for "posted" in your release; replace with configurable mapping if needed
  and inv.xblnr <> ''         // reference invoice number required for duplicate check
  and exists (
    select from rbkp as dup
    {
      dup.belnr
    }
    where
          dup.bukrs = inv.bukrs
      and dup.lifnr = inv.lifnr
      and dup.xblnr = inv.xblnr
      and dup.bldat = inv.bldat
      and dup.rmwwr = inv.rmwwr
      and dup.waers = inv.waers
      and dup.stblg = ''
      and dup.rbstat = '5'    // TODO: same note as above
      and dup.belnr <> inv.belnr
  );
// Assumption: use MM invoice header table RBKP as the primary source for posted vendor invoice duplicates.
// This means the control covers MM/LIV invoice documents, not all FI vendor invoices from BKPF/BSEG.
// Duplicate key chosen per brief: company code, vendor, reference number (XBLNR), invoice date, amount, currency.
// Current design returns one row per duplicate invoice document.
// For better performance/maintainability on large volumes, prefer a layered design:
// 1) base filtered RBKP view
// 2) duplicate-group aggregation view with count(*) > 1
// 3) final exception view joining base rows to duplicate groups.