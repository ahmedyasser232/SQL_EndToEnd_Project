USE Northwind ;
GO
--Task 1 — DDL & Database Design 
	/*
	1.1 Project Audit Log => Create Table named  Project_AuditLog 
	contain Four Column Logid Auto Increment and primary key ,
	Tablename and ActionPerformed Varchar ,
	Actiondate getdate from the system.
	*/
	create table Project_AuditLog
	(
	Logid INT  identity(1,1) PRIMARY KEY,
	TableName Varchar(50) not null,
	ActionPerformed Varchar(50) not null,
	ActionDate datetime Default Getdate()
	)

	--1.2 ALTER TABLE  Add A nullable column called action by to know the name of made the action , Check Constraint LENGHT ActionPerformed > 0
		alter table Project_AuditLog
		add actionby varchar(50) null

		alter table  Project_AuditLog
		add constraint ck_project_auditlog_ActionPerformed
		check(len(ActionPerformed) >0)
	--1.3 DDL Awareness 
	--database-object lifecycle
	--Create Table => Creates A new Table
	-- Alter Table => Modify A structure of an existing table
	-- Drop Table  => Remove  Table And His Structure From DataBase

--Task 2 — SQL Fundamentals & Scalar Functions 
	--2.1 Product Formatting and Categorization  Retrive Productname Capitale Letter and Classification UnitPrice > 50 'Premium'  OtherWise 'Standard'
		select  
		UPPER(productname) as ProductName,
		Case 
			when [UnitPrice] > 50 then 'Premium'  ELSE 'Standard' END AS PriceCategory
		from Products
	--2.2 Filtering To Know Which Item OutOfstock To Recharge It, Sorting unitprice Descing, and Data-Type Conversion   Unitprice To Decima(10,2)
		select ProductName,Cast(UnitPrice as Decimal(10,2)) as UnitPrice from Products
		where UnitsInStock = 0
		order by UnitPrice desc
	--2.3 NULL Handling Check If Region is null or not and Depend on Bussiness Requirment What We Should Do.
		   select EmployeeID ,
		   Title ,
		   Address ,
		   City ,
		   Region,
		   Case When Region is null then 'Missing Value' else 'Real Value'   
		   end as Region_Status
		   from Employees
--Task 3 — Joins, Set Operations, & Aggregations 
	--3.1 Set Operations  Retrive City And Country From Two Different Table And Combined Them Toghther By Using Union Without Duplicates.
		select  city,country from [dbo].[Customers]
		union
		select  city,country from [dbo].[Employees]
	--3.2 Aggregations  Retrive Categoryname and Using Aggregation function to count Product Per Category Then Filteration The Product Have 10 product. 
		select c.categoryname , count(p.[ProductID]) as ProductPerCategory from [dbo].[Categories] c
		join [dbo].[Products] p on c.CategoryID = p.CategoryID
		group by c.CategoryName
		having count(p.[ProductID]) > 10
	--3.3 SELF JOIN  Retrive Empname and his Managername if there no manager for this employee retrun value as empty string.
		select concat(e1.FirstName , ' ' ,  e1.lastname)  AS EmployeeName , concat(e2.FirstName , ' ' ,  e2.lastname) Managername  from Employees e1
		left join Employees e2 on e1.ReportsTo = e2.EmployeeID
	--3.4 INTERSECT the shared City Between Customers and Employees
		select city from [dbo].[Customers]
		intersect
		select city from [dbo].[Employees]
--Task 4 — Subqueries, CTEs, & Intermediate Query Techniques 
	--4.1 CTE  => create cte called Empsales calculate Totalsales per employeeid , return firstname by joining Empsales with Employees Table
		 with EmpSales as 
		 (select employeeid , sum(quantity * unitprice) as TotalSales from [Order Details] od
		 join orders o on o.orderid = od.OrderID
		 group by employeeid
		 )
		 select FirstName , totalsales from EmpSales es 
		 join  Employees  e on e.EmployeeID =es.employeeid
	--4.2 Anti-Join / Subquery Retrun Cutsomers without any orders by both way . 
		select * from (select c.CustomerID , o.orderid from Customers  c left join  orders o  on o.customerid = c.customerid  ) as Cuswithoutorders where orderid is null
		select c.CustomerID from Customers c where not exists  (select * from orders o where c.CustomerID = o.CustomerID )
	--4.3 Correlated Subquery Retrun The Product Which Higher Than Avg(unitprice) but use the correlated subquery to  make iterattion to  compare between p1.categoryid and p2.category 
		select productid , productname , unitprice from [dbo].[Products] p1
		where unitprice > (select avg(UnitPrice) from Products p2 where p1.CategoryID = p2.categoryid )
	--4.4 Local Temporary Table create  #TopProducts temporary table and return top 10 high value products
		DROP TABLE IF EXISTS #TopProducts;
		create  table #TopProducts
		(productid int primary key ,
		productname nvarchar(40) not null ,
		unitprice  money )
		insert into #TopProducts
		select top 10 [ProductID],[ProductName],[UnitPrice] from Products order by UnitPrice desc 
		select * from #TopProducts;
	--4.5 Table Variable declare variable table to store categories Information.
		declare  @TopCategories table 
		(categoryid int primary key ,
		categoryname nvarchar(15) not null ,
		Description ntext,
		picture image
		)
		insert into @TopCategories  (categoryid,categoryname,Description,picture)
		select categoryid ,categoryname,Description,picture  from Categories
		select * from @TopCategories
	--4.6 Global Temporary Table — Conceptual Checkpoint 
		/* Global Temporary Table ## :
									scope=>		   Autmaticlly Deleted At The End Of Session And Aother Session That created it in That Are Reference It
									Visabilty=>    Visiable In All Session
									Use Case=>     Use For Collaborative Tasks When Multisession Share in The Same Temp Table
									security=>     Less Secure Because No Isolation From Other
									Preformance=>  Possible Contention or concurrency problems.
	   	 local Temporary Table ## :
									scope=>		   Autmaticlly Deleted At The End Of Session
									Visabilty=>    Visiable In the session is where they are Created
									Use Case=>     Tasks Specific To Single User
									security=>     more Secure Because There is Isolation Layer
									Preformance=>  No Contention or concurrency problems.

		Why a global temporary ?
								Becuase It may Possible Contention or concurrency problems and  Less Secure Because No Isolation From Other
																																			*/

--Task 5 — Views, Procedures, & Functions 
	--5.1 Standard View  => create view vw_CustomerOrderSummary retrive  ( customerid , companyname , calculate numberofordders )
		create view vw_CustomerOrderSummary as (
		select c.customerid ,c.companyname , sum(o.orderid) as NumberofOrders from Customers c
		join orders o on c.CustomerID = o.CustomerID
		group by c.CustomerID , c.companyname
		)
	--5.2 Stored Procedure Retrive * from orders table where customerid = 'ALFKI'
		create or alter  proc sp_GetCustomerOrders 
		@CustomerID as NCHAR(5)
		as
		begin
		select * from orders
		where customerid = @CustomerID
		end;
		
		exec sp_GetCustomerOrders
		@CustomerID = 'ALFKI' 
	--5.3 User-Defined Function create function return number of ordercount based on customerid
		create or alter function dbo.fn_GetCustomerOrderCount (@CustomerID NCHAR(5))
		returns int
		as
		begin 
				DECLARE @ordercount int 
				select  @ordercount = count([OrderID]) from [dbo].[Orders]
				where customerid = @CustomerID
				return @ordercount
		end 
		select dbo.fn_GetCustomerOrderCount('VINET') as ordercount
	--5.4 Indexed / Materialized View Awareness 
		--Materialized View:
								--Defenition:	Logical View of data Driven By Select Query in Which the Result of query stores in disk
								--Storage:		Stored in the Disk
								-- Preformance: Faster
								--Realability: Not Need To Update View Each Time When Used it.

		-- View:
								--Defenition:	DataBase Object That ALLOWS Generate a logical Subset of data from one or more table
								--Storage:		Stored in the memory
								-- Preformance: slow
								--Realability:  Need To Update View Each Time When Used it.

--Task 6 — Transactions & Error Handling 
	--6.1 Explicit Transaction begin try   update unitprice then retrive value 1 / 0  in this case the commit can't be done 
	--6.2 Error Handling    begin catch then rollback the changes because @@transcount > 0 and print error message
	--6.3 Savepoint  
		Begin Try
				begin Transaction
					save transaction PriceBeforeUpdate
						update [dbo].[Products]
						set unitprice =unitprice + 5
						where productid = 1
						select 1 / 0
				commit Transaction
		 End Try

		 Begin Catch 
					If @@TRANCOUNT > 0
					 ROLLBACK TRANSACTION
					 Select  ERROR_MESSAGE() as Errormessage
		 End Catch ;
	
	--6.4 Transaction Concepts: 
								--ACID:
										--Automicity:   Commit All Or Nothing
										--Consistency:  Transation From ValidState To Another ValidState
										--Isolation:    Concurrent Transaction Are isolated From Each Other
										-- Duraability: Data presist After Commit even in  The System Failure
								
								--Blocking: Linear Queue When The Session Wait For Another Session Finish and release A lock 
								
								/*Deadlock: circular dependency  where two or more session waits each hold a lock the other need
											forcing Database Engine To Terminate one session as Deadlock Victim. */
  
  
  --Task 7 — Triggers for Automation
	--7.1 UPDATE Trigger create table  Project_AuditLog then create trigger after update to retrive value updated .
		    drop  table if exists  Project_AuditLog
		    create table Project_AuditLog
		    (Log_id int identity(1,1) primary key,
		    Tablename varchar(30),
		    actionperformed varchar(50),
		    actiondate datetime default getdate())

			create or alter trigger	trg_AuditProducts 
			on products
			after update
			as
			begin
			insert into Project_AuditLog 
			(TableName ,ActionPerformed)
			values('Products','Product Updated')
			end

		--7.2 DELETE Trigger Create Trigger To Know Deleted Values.
			create or alter trigger	trg_AuditProducts 
			on products
			after delete
			as
			begin
			insert into Project_AuditLog 
			(TableName ,ActionPerformed)
			values('Products','Product Deleted')
			end
		--7.3 Trigger Safety 
			-- Why triggers should be kept small and controlled. 
				-- Becuase Trigger Automaticlly Run With (DELETED , Inserted , Update) That Reduce Preformance it should use in special case.
				--IF Process Fail It May Doing Rollback in this case we did'nt know what happen
				-- Difficult in Debuging with large trigger
			-- Why trigger logic can introduce hidden performance or maintenance costs. 
				-- Becuase Trigger Automaticlly Run With (DELETED , Inserted , Update) That Reduce Preformance 
			-- Why trigger code should be written with multi-row statements in mind.
				-- Because Delete and Update Can Effect Multirows it can return not the real amount of data and it's effect on data integrity

		--7.4 INSTEAD OF Trigger — Conceptual Checkpoint
			--Add a SQL comment explaining one situation where an INSTEAD OF trigger could be useful, such as when controlling operations against a view. 
				/* We can Just Update Original Table Instead Of View When Unitcostchange 
				example:
					Create or alter trigger trg_UpdateProductsView
					on vw_Products
					instead of update
					as
					begin
					update products p
					set p.unitprice = i.unitprice
					from products p , inserted i 
					where p.productid = i.productid
					end;
					*/


--Task 8 — MERGE, Incremental Loading, & Delete Handling 
	--8.1 Staging Table 
		create table  #Staging_Shippers 
		( ShipperID  INT,
		  CompanyName  NVARCHAR(50))
		GO
		Insert into   #Staging_Shippers  values (1, 'Speedy Express V2' ),(4 , 'Global Logistics')
		GO
	--8.2 MERGE Synchronization Making Merge If The value matched just Update companyname if not matched the target insert shipperid and companyname and turn on manual id insertion.
		SET IDENTITY_INSERT dbo.Shippers ON;
		MERGE INTO [dbo].[Shippers]  S USING #Staging_Shippers SS
		ON S.SHIPPERID = SS.SHIPPERID 
		when matched then update 
		set s.companyname = ss.companyname
		when not matched by target then insert (ShipperID , CompanyName ) values (ss.shipperid ,ss.companyname);
	--8.3 Incremental Extraction / Watermark  maxdate in orderdate return to '1998-6-1' and the last time insert the newest value in '1998-5-1' 
	--after this date we should incremet the newest data to  make concurrency  to database and avoid full load.
		declare @watermark Datetime = '1998-5-1'
		select * from orders
		where OrderDate > @watermark;
	--8.4 Delete Handling use anti join to return the value in shippers but not in #stagingshippers
		select s.* from [dbo].[Shippers] s
		left join #Staging_Shippers SS on S.SHIPPERID = SS.SHIPPERID 
		where SS.SHIPPERID  is null
		/*
		Soft Delete: Hide From The Application Can Recover In Anytime Because The History is exists and still in the db
		Hard Delete: It Remove From Database Can't Be Recover
		Why delete handling should be explicitly controlled:Becuase If You Can't Handle Delete,By wrong You Can Remove Important Data From Database Forever.
		*/
	--8.5 Idempotency:
					-- If the record already exists, it is updated; otherwise, a new record is inserted.

--Task 9 — Advanced Analytics with Window Functions
	--9.1 Ranking use window function ranking and dense_rank  to rank products by each categoryid based on unitprice desencing
		Select categoryid ,
		ProductName  ,
		UnitPrice,
		rank() over(partition by categoryid order by unitprice desc ) as Ranking_Price,
		dense_rank() over(partition by categoryid order by unitprice desc ) as Dense_Ranking_Price
		from Products
	--9.2 Trend Analysis with LAG Return The Preveios Order by The Same Customer
		select orderid ,
		customerid ,
		OrderDate ,
		lag(orderdate) over (partition by customerid order by orderdate asc) as previos_order_by_customer
		from orders
	--9.3 Latest Record Selection  use subquery to retrive Row_number and comapare rn with 1 to return The latest Order.
	    select * from ( 
	    select  
	    OrderID, 
        CustomerID, 
        OrderDate,
		ROW_NUMBER() over(partition by customerid order by orderdate desc) as  rn   from orders  ) as  T
		where rn = 1
	--9.4 NTILE Divied UnitPrice For 4 Division To Define Quartile UnitPrice
		select productid ,
			   unitprice ,
			   ntile(4) over (order by unitprice desc ) as Quartile_Unitprice
			   from Products
	--9.5 Running Total  Use Sum with over and order by productid to return cumulative value to current row.
		select 
		productid,
		unitprice,
		sum(unitprice) over(order by productid rows between unbounded  preceding and  current row) as Cumulative_value
		from products
--Task 10 — Query Optimization, Indexing, Partitioning, & Statistics 
	--10.1 Covering Index Create Non-clustered index on customerid include addition column orderdate ,freight 
		create nonclustered  index IX_Orders_CustomerID 
		on orders(customerid) include(orderdate,freight)
		
	--10.2 Sargability use range to orderdate to allows seek scan and reduce fullscan(force scan) by calculate year first to each row.
		SELECT OrderID FROM Orders WHERE orderdate >= '1997-1-1' and orderdate < '1998-1-1'; 
	--10.3 Execution Plan in 
		-- Original Non-Sargable Query:
		-- Physical Operation: Index Scan
		-- YEAR(OrderDate) applies a function to the column,
		-- making an Index Seek on OrderDate more difficult. 
			SELECT OrderID FROM Orders WHERE YEAR(OrderDate) = 1997
		-- Sargable Rewritten Query:
		-- Physical Operation: Index Seek
		-- The date range allows the optimizer to seek directly
		-- to the required range when a suitable index exists.
			SELECT OrderID FROM Orders WHERE orderdate >= '1997-1-1' and orderdate < '1998-1-1' 

	--10.4 Statistics 
		 UPDATE STATISTICS Orders;
		 --Add a SQL comment explaining why database statistics are important to the Query Optimizer:
			-- Database statistics provide information about data distribution and row counts.
			-- The Query Optimizer uses these statistics to estimate cardinality and choose
			-- an efficient execution plan, including the appropriate index access method.
	--10.5 Index Engineering Concepts 
		/*
		B-Tree:A B-Tree is a balanced tree data structure used to organize data and speed up searching in database indexes.
			   It supports efficient search, insertion, and deletion by keeping data sorted and reducing the number of disk accesses.

	    Selectivity:is the percentage of rows that match a specific query condition. High selectivity means fewer rows match,
		            while low selectivity means many rows match.

		Clustered Index: Determines the physical order of data rows in a table. A table can have only one clustered index.

		Non-Clustered Index: A separate structure that stores indexed key values and row locators to find data without scanning the entire table.
		A table can have multiple non-clustered indexes

		Composite Index: An index built on two or more columns, useful for queries filtering or sorting by those columns.
		The column order matters.
		*/
	--10.6 Partitioning — Conceptual Checkpoint
		-- A suitable column for partitioning an Orders/Sales table is OrderDate.
		-- Partitioning by date allows Partition Elimination, enabling SQL Server
		-- to scan only the relevant date partitions instead of accessing all partitions.




		
				
				
		




		
		
										
										
	 
		







