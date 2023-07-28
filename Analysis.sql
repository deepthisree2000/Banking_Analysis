use inclass;
show tables;

/*1.Print credit card transactions with sum of transaction_amount on all Fridays 
	and sum of transaction_amount on all other days. */ 
SELECT ABS(SUM(IF(dayname(Transaction_Date)="Friday",Transaction_amount,0)))FRIDAY_TRANSACTION,
       ABS(SUM(IF(dayname(Transaction_Date)!="Friday",Transaction_amount,0)))NON_FRIDAY_TRANSACTION
FROM bank_account_transaction
WHERE account_number IN
                       (SELECT account_number FROM bank_account_details 
						WHERE account_type LIKE "%Credit Card%"); -- subquery approach

WITH SUMS AS 
     (SELECT T2.* FROM (SELECT account_number FROM bank_account_details 
						WHERE account_type LIKE "%Credit Card%")T1,
             bank_account_transaction T2 
             WHERE T1.account_number=T2.account_number)
SELECT ABS(SUM(IF(dayname(Transaction_Date)="Friday",Transaction_amount,0)))FRIDAY_TRANSACTION,
       ABS(SUM(IF(dayname(Transaction_Date)!="Friday",Transaction_amount,0)))FRIDAY_TRANSACTION
FROM SUMS;  -- with approach

/*2.Show the details of credit cards along with the aggregate transaction 
	amount during holidays and non holidays.*/  
WITH TRANS AS 
     (SELECT T2.* FROM (SELECT account_number FROM bank_account_details 
						WHERE account_type LIKE "%Credit Card%")T1,
             bank_account_transaction T2 
             WHERE T1.account_number=T2.account_number)
SELECT Account_number,
ABS(SUM(IF(trans.transaction_date IN (SELECT holiday from bank_holidays),trans.transaction_amount,0)))ON_HOLIDAY,
ABS(SUM(IF(trans.transaction_date NOT IN (SELECT holiday from bank_holidays),trans.transaction_amount,0)))NON_HOLIDAYS
FROM TRANS
GROUP BY Account_number;
   
/* 3.Generate a report to Send Ad-hoc holiday greetings - “Happy Holiday” 
	 for all transactions occurred during Holidays in 3rd month. */
SELECT Account_number,Transaction_date,
IF(Transaction_Date in (SELECT Holiday from bank_holidays) 
										   and month(Transaction_Date)=3,"Happy Holiday",0)Message
FROM bank_account_transaction
WHERE Transaction_Date in (SELECT Holiday from bank_holidays where month(Transaction_Date)=3); -- my approach

WITH BCD AS 
(SELECT * FROM bank_account_transaction
 WHERE transaction_date IN (SELECT holiday FROM bank_holidays where month(Transaction_Date)=3))
 SELECT BCD.Account_number,BCD.Transaction_date,"Happy Holiday" message 
 FROM BCD; -- eshwar approach

/* 4.Calculate the Bank accrued interest with respect to their RECURRING DEPOSITS  for any deposits 
	 older than 30 days .
Note: Accrued interest calculation =  transaction_amount * interest_rate 
Note: use CURRENT_DATE() */
WITH ABC AS
(SELECT BAT.* FROM (SELECT * FROM bank_account_details  WHERE account_type="RECURRING DEPOSITS")BAD,
				bank_account_transaction BAT
                WHERE BAT.account_number=BAD.account_number)
SELECT ABC.account_number,BIR.account_type,SUM(ABC.transaction_amount*BIR.interest_rate)Interest_Amount
FROM ABC,bank_interest_rate BIR
WHERE BIR.account_type="Recurring Deposits" AND ABC.transaction_date < date_sub(curdate(),interval 30 day)
GROUP BY ABC.account_number; -- my approach

WITH ABC AS 
(SELECT BAD.*
         FROM bank_account_details BAD,bank_interest_rate BIR
		 WHERE BAD.Account_type=BIR.Account_type
         AND BAD.Account_type="RECURRING DEPOSITS")
SELECT ABC.Account_number,ABC.Account_type,SUM((BAT.Transaction_amount*
	(SELECT interest_rate FROM bank_interest_rate WHERE account_type="RECURRING Deposits")))Interest
FROM ABC,bank_account_transaction BAT
WHERE ABC.Account_number=BAT.Account_number AND  BAT.Transaction_Date < date_sub(curdate(),interval 30 day)
GROUP BY ABC.Account_number; -- charan approach

/*5.Display the Savings Account number whose corresponding Credit cards and  
    AddonCredit card transactions have occured more than one time. */
with abc as (
select Account_Number,Account_type from bank_account_details 
where Account_type="Savings" AND 
Account_Number in 
(select linking_account_number from bank_account_relationship_details 
where Account_type in ("Credit Card","Add-on Credit card")))
SELECT (abc.account_number)Savings_Accuntnumber,
	   (abc.account_type)Savings_Accounttype,
       (BARD.Account_Number)Credit_Card_Number,
       (BARD.account_type)Credit_Card_Accounttype,
       (COUNT(distinct(BAT.Account_Number)))Count_Of_Transactions
FROM abc,bank_account_relationship_details BARD,bank_account_transaction BAT
WHERE abc.account_number=BARD.linking_account_number
AND BARD.Account_type in ("Credit Card","Add-on Credit Card")
AND BAT.account_number in (SELECT linking_account_number from bank_account_relationship_details 
						   WHERE  account_type in 	("Credit Card","Add-on Credit Card"	));		 -- one approach

WITH ABC AS 
(SELECT BAT.* ,BARD.linking_account_number,BARD.account_type
FROM (SELECT *  FROM bank_account_relationship_details where account_type in 
                                                       ("CREDIT CARD","Add-on credit card"))BARD,
	 bank_account_transaction BAT
WHERE BAT.account_number=BARD.account_number)
SELECT (BAD.account_number)Savings_account_number,
       (BAD.account_type)Savings_account_type,
       (ABC.account_number)CreditCard_accountnumber,
       (ABC.account_type)CreditCard_accounttype,
	   count(abc.account_number)Count_of_transactions
FROM ABC,bank_account_details BAD
where BAD.account_number=ABC.linking_account_number
GROUP BY BAD.account_number,BAD.account_type,ABC.account_number,ABC.account_type
HAVING Count_of_transactions>1 ; -- another approach

/* 6.Display the Savings Account number whose corresponding 
	 AddonCredit card transactions have occured atleast once. */
WITH ABC AS 
(SELECT BAT.* ,BARD.linking_account_number,BARD.account_type
FROM (SELECT *  FROM bank_account_relationship_details where account_type in ("Add-on credit card"))BARD,
	 bank_account_transaction BAT
WHERE BAT.account_number=BARD.account_number)
SELECT (BAD.account_number)Savings_account_number,
       (BAD.account_type)Savings_account_type,
       (ABC.account_number)CreditCard_accountnumber,
       (ABC.account_type)CreditCard_accounttype,
	   count(abc.account_number)Count_of_transactions
FROM ABC,bank_account_details BAD
where BAD.account_number=ABC.linking_account_number
GROUP BY BAD.account_number,BAD.account_type,ABC.account_number,ABC.account_type
HAVING Count_of_transactions=1 ;

/*7.Print the customer_id and length of customer_id using Natural join on 
Tables :bank_customer  and  bank_customer_export 
Note: Do not use table alias to refer to column names.*/
select customer_id,length(customer_id) length_of_id
from bank_customer BC
NATURAL  JOIN bank_customer_export BCE;

/*8.Print customer_id, customer_name and other common columns  from both the Tables : 
bank_customer & bank_customer_export without missing any matching customer_id key column records. 
Note: refer datatype conversion if found any missing records. */
SELECT BC.customer_id,BC.customer_name
FROM bank_customer BC
NATURAL JOIN bank_customer_export BCE;
     









             
             
             
             
             
             

			




