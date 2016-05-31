#!/usr/bin/bash

FILESIZE=`du -k "$1" | cut -f1`

echo $FILESIZE

if [ $FILESIZE -gt "85000" ]; then

mysqlexe="/usr/local/mysql/bin/mysql --verbose --user root --password=znerol123"
${mysqlexe} <<TAG

	set @snapshotId = folio.insertSnapshot('$1');

	LOAD DATA INFILE '$1' 
	INTO TABLE folio.SnapShots 
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n'
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
	set snapshotId=@snapshotId;

	#call folio.populateInferredSales(@snapshotId);
	call folio.computeDeltas(@snapshotId);
;
TAG

fi

