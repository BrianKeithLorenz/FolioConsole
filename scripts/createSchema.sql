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
SnapshotId int, 
Delta varchar(1)
);

create index DeltaIndex on Folio.snapshots(Delta);

drop table if exists Folio.NoteDelta;

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

insert into Folio.SnapshotIds values("Baseline",1);

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
		insert into Folio.NoteDelta select x.noteID, x.snapshotId, "D" as Delta from 
		(select s.* from Folio.snapshots s where s.snapshotId = previousSnapshotId) x 
		left join (select t.noteId from Folio.snapshots t where t.snapshotId = currentSnapshotId) y on
		x.noteId = y.noteId where y.noteId is null on duplicate key update noteId = x.noteId;
        
        
        
        delete from Folio.snapshots where snapshotId = previousSnapshotId and noteId not in
		  (select noteId from Folio.inferredSales where snapshotid = previousSnapshotId);
    end if;
    
END$$
DELIMITER ;

drop procedure if exists folio.computeDeltas;
DELIMITER $$
create procedure folio.computeDeltas(IN currentSnapshotId int)
BEGIN
    declare previousSnapshotId int;

    select max(snapshotId) from snapshots 
		where snapshotId < currentSnapshotId into previousSnapshotId;
        
	if (previousSnapshotId = null)
    then
		select 1 into previousSnapshotid;
    end if;
        
    
    if ( exists (select * from Folio.SnapshotIds where snapshotId = currentSnapshotId) and
         exists (select * from Folio.SnapshotIds where snapshotId = previousSnapshotId)
         or not exists (select * from snapshots where snapshotId = previousSnapshotId) #snapshot table is empty
    ) 
    then
		#Mark newly deleted rows
		update folio.snapshots set Delta="D" where noteId in (select x.noteId from
		(select s.* from Folio.snapshots s where s.snapshotId = previousSnapshotId) x 
		left join (select t.noteId from Folio.snapshots t where t.snapshotId = currentSnapshotId) y on
		x.noteId = y.noteId where y.noteId is null) and snapshotId = previousSnapshotId;
        
        #Mark newly inserted rows
        update folio.snapshots set Delta="I" where noteId in (select x.noteId from
		(select s.* from Folio.snapshots s where s.snapshotId = currentSnapshotId) x 
		left join (select t.noteId from Folio.snapshots t where t.snapshotId = previousSnapshotId) y on
		x.noteId = y.noteId where y.noteId is null) and snapshotId = currentSnapshotId;
        
        #Mark rows which have a price change.
        update folio.snapshots set Delta="U" where noteId in (select x.noteId from
		(select s.* from Folio.snapshots s where s.snapshotId = currentSnapshotId) x,
		(select t.noteId, t.AskPrice from Folio.snapshots t where t.snapshotId = previousSnapshotId) y where
		x.noteId = y.noteId and x.AskPrice <> y.AskPrice) and snapshotId = currentSnapshotId;
        
        #Clear out redundant unmodified entries
        delete from Folio.snapshots where snapshotId = previousSnapshotId and Delta is null;
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




