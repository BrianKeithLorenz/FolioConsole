#!/usr/bin/bash

mysqlexe="/usr/local/mysql/bin/mysql --verbose --user root --password=znerol123"
${mysqlexe} <<TAG

drop table if exists Folio.Snapshots;
create table Folio.Snapshots 
(
InsertTime timestamp,
LoanId varchar(128),
NoteId varchar(128),
OrderId varchar(128),
OutstandingPrincipal varchar(128),
AccruedInterest float,
StatusInd varchar(128),
AskPrice decimal(10,2),
MarkupDiscount float,
YTM varchar(128),	
DaysSinceLastPayment varchar(128),
CreditScoreTrend varchar(128),
FICORange varchar(128),
DateTimeListed varchar(128),
NeverLate varchar(128),
LoanClass varchar(128),
LoanMaturity int,
OriginalNoteAmount decimal(10,2),
InterestRate float,
RemainingPayments int,
PrincipalPlusInterest decimal(10,2),
ApplicationType varchar(128),
SnapshotId int
);

drop table if exists Folio.InferredSales;
create table Folio.InferredSales
(
NoteId varchar(128),
SnapshotId int,

primary key(NoteId, SnapshotId)
);


drop table if exists Folio.SnapshotIds;
#Snapshots assumed to be inserted in time order such
#that increasing snapshot ids correspond to later
#snapshots.
create table Folio.SnapshotIds
(
	InventoryFileName varchar(512),
    SnapshotId int auto_increment,
    
    primary key(SnapshotId)
);



CREATE INDEX NoteIdIndex ON Folio.Snapshots (NoteId);
CREATE INDEX SnapshotIdIndex ON Folio.Snapshots (SnapshotId);


#CREATE
#[DEFINER = { user | CURRENT_USER }]
#    FUNCTION sp_name ([func_parameter[,...]])
#    RETURNS type
#    [characteristic ...] routine_body




drop function if exists folio.insertSnapshot;
DELIMITER $$
create function folio.insertSnapshot(fileName varchar(128)) returns int
BEGIN
	declare returnValue int;
    insert into Folio.SnapshotIds set InventoryFileName=fileName;
    select max(SnapshotId) from SnapshotIds into returnValue;
	return (returnValue);
END$$
DELIMITER ;


drop function if exists folio.insertSnapshot;
DELIMITER $$
create function folio.insertSnapshot(fileName varchar(128)) returns int
BEGIN
	declare returnValue int;
    insert into Folio.SnapshotIds set InventoryFileName=fileName;
    select max(SnapshotId) from SnapshotIds into returnValue;
	return (returnValue);
END$$
DELIMITER ;


drop procedure if exists folio.populateInferredSales;
DELIMITER $$
create procedure folio.populateInferredSales(IN currentSnapshotId int)
BEGIN
    declare previousSnapshotId int;

    select max(snapshotId) from snapshots 
		where snapshotId < currentSnapshotId into previousSnapshotId;
    
    if ( exists (select * from Folio.SnapshotIds where snapshotId = currentSnapshotId) and
         exists (select * from Folio.SnapshotIds where snapshotId = previousSnapshotId)
    ) 
    then
		insert into Folio.inferredSales select x.noteID, x.snapshotId from 
		(select s.* from Folio.snapshots s where s.snapshotId = previousSnapshotId) x 
		left join (select t.noteId from Folio.snapshots t where t.snapshotId = currentSnapshotId) y on
		x.noteId = y.noteId where y.noteId is null on duplicate key update noteId = x.noteId;
    end if;
    
END$$
DELIMITER ;

drop procedure if exists folio.removeSnapshot;
DELIMITER $$
create procedure folio.removeSnapshot(IN inSnapshotId int)
BEGIN
    delete from folio.snapshots where snapshotId = inSnapshotId;
    delete from folio.snapshotIds where snapshotId = inSnapshotId;
    delete from folio.inferredSales where snapshotId = inSnapshotId;
END$$
DELIMITER ;


;
TAG

