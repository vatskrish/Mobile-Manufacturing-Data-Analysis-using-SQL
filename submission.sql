--Q1    Get all the records from last 59 days and last 77 days

SELECT *
FROM      FACT_TRANSACTIONS

where     Date >DATEADD(day,-59,(select max(Date) FROM FACT_TRANSACTIONS)) 
and 
     	  Date < DATEADD(day,-77,(select max(Date) FROM FACT_TRANSACTIONS))







--Q2    Get All the records from last 7 months from fact transaction table


SELECT     *
FROM       FACT_TRANSACTIONS
where      Date >DATEADD(MONTH,-7,(select max(Date) FROM FACT_TRANSACTIONS))





--Q3    show the transaction recency from the maximum date

SELECT     *
           ,datediff(day,Date,(select max(Date) from FACT_TRANSACTIONS)) as Recency
FROM       FACT_TRANSACTIONS 





SELECT     *
           ,dateadd(day,(select max(Date) from FACT_TRANSACTIONS),Date) as Recency
FROM       FACT_TRANSACTIONS 





--Q4      what was the total sales in each month of every year

select  Datepart(year,Date) as [Year]
        ,DATENAME(MONTH,Date) as [Month]
		,SUM(TotalPrice) as [Total Amount]

from    FACT_TRANSACTIONS

group by Datepart(year,Date)
         ,DATENAME(MONTH,Date)

order by Year






--Q5     What is total sales on weekends and weekdays 



with tab as (

            select     *
                       ,DATENAME(weekday,Date) as [day_name]

	                   ,DATEPART(weekday,Date) as [day_num]

	                   ,case when DATENAME(weekday,Date) in('Saturday','Sunday') then 'Weekend'
	                   else 'Weekday' end as [day_type]

                       from FACT_TRANSACTIONS
           )


select    day_type, sum(TotalPrice) as [Total Sales] from tab
group by  day_type








--Q6    Average price of top 5 manufacturer in USA



select   top 5
         manufacturer.Manufacturer_Name

       , location.Country
       , avg(fact.TotalPrice) as [Avg Amount]



from        FACT_TRANSACTIONS as fact

inner join  DIM_MODEL as model
on          fact.IDModel = model.IDModel


inner join  DIM_MANUFACTURER as manufacturer
on          model.IDManufacturer = manufacturer.IDManufacturer


inner join DIM_LOCATION location
on         location.IDLocation = fact.IDLocation


where      location.Country = 'US'


Group by   manufacturer.Manufacturer_Name, location.Country


order by   [Avg Amount] desc



--Q7    2nd and 3rd best zip code in each state of usa for the year 2009 in terms of transaction



with tab as (

             select      loc.State, loc.ZipCode, count(*)  [transactions]

             from        FACT_TRANSACTIONS as trans


             inner join  DIM_LOCATION as loc
             on          trans.IDLocation = loc.IDLocation

             where       Country ='US'
             and         datepart(year,Date) = 2009

             group by    loc.State, loc.ZipCode

           ),      -- TOTAL COUNT FOR EACH STATE AND ZIPCODE



tab2 as (
         select *
        , DENSE_RANK() over( partition by [State] order by transactions desc) [rank] from tab
		
        )  -- RANK EACH STATE BY NUMBER OF TRANSACTIONS




select * from tab2
where [rank] in  (2,3)     -- 2ND AND 3RD BEST ZIPCODE IN EACH STATE IN TERMS OF TRANSACTIONS







--Q8   2nd best product in terms of sales in each country for year 2009 and 2010


with cte1 as(

             select loc.Country,trans.IDModel,DATEPART(year,trans.Date) as [year], sum(trans.TotalPrice) as [total_sales]

             from FACT_TRANSACTIONS as trans


inner join DIM_LOCATION as loc
on         trans.IDLocation= loc.IDLocation


where      DATEPART(year,trans.Date) in (2009,2010)

           group by loc.Country,trans.IDModel, DATEPART(year,trans.Date)    -- step 2 complete
 
),       --		TOTAL SALES BY YEAR, COUNTRY, MODEL 

cte2 as (

       select  Country,IDModel, [year], SUM(total_sales) [total_sales]
        from cte1
        group by Country,IDModel, [year]


         ) ,   -- group by country id mdoel and sum price. so that there is only one record for each model for each country
		       -- which can be later ranked within year for that country

cte3 as (

         select *
         ,  DENSE_RANK() over(partition by [year] order by total_sales  desc) [rank]
         from cte2
     --  -- rank model for each product in each country in each year


        )

select * from cte3
where rank in (2,3)       -- 2 AND 3 RANKED MODEL IN EACH COUNTRY IN TERMS OF TOTAL AMOUNT SOLD







-- Q9  What is the percentage contribution of each model in total sales for each country


with cte1 as (
              select          model.Model_Name,trans.IDModel
			                 ,trans.IDLocation, trans.TotalPrice

                              , sum(trans.TotalPrice) over (partition by trans.IDLocation, trans.IDModel ) as [amount]   


              from            FACT_TRANSACTIONS as trans

             inner join      DIM_MODEL as model
             on              trans.IDModel=model.IDModel

             -- order by amount     -- THIS IS HOW YOU ORDER WITHOUT MAKING ROLLING TOTAL       BUT BUT BUT YOU CANNOT ORDER BY INSIDE
)

select        *
              ,round(
	             100 * ( ( CONVERT ( float , amount )    -    TotalPrice) / amount) 
		     , 2
		     ) as [percent_contri]

from cte1 

order by IDLocation, percent_contri desc



