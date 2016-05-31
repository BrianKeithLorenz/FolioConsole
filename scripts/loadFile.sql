LOAD DATA INFILE '/Users/blorenz/inventory/FolioInventory.2016.05.19.06.54.40.csv' 
INTO TABLE folio.SnapShots 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY ''
IGNORE 1 ROWS
(
LoanId,
NoteId,
OrderId,
OutstandingPrincipal,
AccruedInterest,
StatusInd,
AskPrice,
MarkupDiscount,
YTM,	
DaysSinceLastPayment,
CreditScoreTrend,
FICORange,
DateTimeListed,
NeverLate,
LoanClass,
LoanMaturity,
OriginalNoteAmount,
InterestRate,
RemainingPayments,
PrincipalPlusInterest,
ApplicationType
)
set InventoryFileName='/Users/blorenz/inventory/FolioInventory.2016.05.19.06.54.40.csv'
;
