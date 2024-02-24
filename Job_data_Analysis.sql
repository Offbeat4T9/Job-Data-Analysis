--Table visualisation
select *
from MyPortfolio.dbo.Job_data;

--------------------------------------=-----------------------DATA CLEANING--------------------------------------------------------------------------
--1. Converting the salary given from string to integer and take the minimum salary from range
--2. Format the salary and convert it into Lakhs per annum
--3. Handling missing value using central tendencies 
--4. Dropping useless columns


--Creating new column as Expected_Salary_LPA
ALTER TABLE MyPortfolio.dbo.Job_data
ADD Expected_Salary_LPA NVARCHAR(255);


--Setting value in Expected_Salary_LPA by choosing the minimum value from range from Salary column 
UPDATE MyPortfolio.dbo.Job_data
SET Expected_Salary_LPA=CASE
WHEN SALARY LIKE '%-%' THEN TRIM(SUBSTRING(SALARY,1,CHARINDEX('-',SALARY)-1))
WHEN SALARY NOT LIKE '%-%' AND SALARY<>'NOT AVAILABLE' THEN TRIM(SUBSTRING(SALARY,1,CHARINDEX('(',SALARY)-1))
ELSE NULL
END
FROM MyPortfolio.dbo.Job_data; 


--Converting the salary given in Thousands to Lakhs per annum and removing the String
UPDATE MyPortfolio.dbo.Job_data
SET Expected_Salary_LPA=CASE
WHEN Expected_Salary_LPA LIKE '%T%' THEN CONVERT(FLOAT,TRIM(SUBSTRING(Expected_Salary_LPA,1,CHARINDEX('T',SALARY)-1)))*0.12
WHEN Expected_Salary_LPA LIKE '%L%' THEN CONVERT(FLOAT,TRIM(SUBSTRING(Expected_Salary_LPA,1,CHARINDEX('L',SALARY)-1)))
ELSE NULL
END
FROM MyPortfolio.dbo.Job_data; 


--Converting the column from string to float
ALTER TABLE MyPortfolio.dbo.Job_data
ALTER COLUMN Expected_Salary_LPA FLOAT;


--Average salary based on post and location
select post,location,avg(Expected_Salary_LPA) over (partition by post,location) as Avg_Salary
from MyPortfolio.dbo.Job_data;


--Salary given per hour basis
select *
from MyPortfolio.dbo.Job_data
where Salary like '%Per Hour%';


--Expected Salary LPA if they work 8 hours/day, 24 days/month 
select Salary,
case
when Salary like '%-%' then convert(Float,TRIM(SUBSTRING(SALARY,1,CHARINDEX('-',SALARY)-1)))*8*24*12*0.00001
when Salary not like '%-%' then convert(Float,TRIM(SUBSTRING(SALARY,1,CHARINDEX('Per',SALARY)-1)))*8*24*12*0.00001
end as Salary_LPA
from MyPortfolio.dbo.Job_data
where Salary like '%Per Hour%';


--Updating Expected Salary of Per hour exployees
UPDATE jd
set jd.Expected_Salary_LPA=update_jd.Salary_LPA
from MyPortfolio.dbo.Job_data jd
inner join
(select Salary,
 case
 when Salary like '%-%' then convert(Float,TRIM(SUBSTRING(SALARY,1,CHARINDEX('-',SALARY)-1)))*8*24*12*0.00001
 when Salary not like '%-%' then convert(Float,TRIM(SUBSTRING(SALARY,1,CHARINDEX('Per',SALARY)-1)))*8*24*12*0.00001
 end as Salary_LPA
 from MyPortfolio.dbo.Job_data
 where Salary like '%Per Hour%') as update_jd
on jd.Salary=update_jd.Salary


--Average salary based on post and location where the expected salary is NULL
SELECT a.post,a.location,avg(a.Expected_Salary_LPA) over (partition by a.post,a.location) Avg_min_sal,b.post,b.Location,b.Expected_Salary_LPA
FROM MyPortfolio.dbo.Job_data a 
JOIN 
MyPortfolio.dbo.Job_data b
ON a.POST=b.post and a.Location=b.Location
where b.Expected_Salary_LPA is null


--Updating the Expected salary with averages salary based on post and location
UPDATE a
set a.Expected_Salary_LPA=b.Avg_min_sal
from MyPortfolio.dbo.Job_data a
inner join
(select post,location,avg(Expected_Salary_LPA) over (partition by post,location) Avg_min_sal from MyPortfolio.dbo.Job_data) as b
ON a.POST=b.post and a.Location=b.Location
where a.Expected_Salary_LPA is null;


--Average salary based on job domain and location where the expected salary is NULL
SELECT a.Job_Domain,a.location,avg(a.Expected_Salary_LPA) over (partition by a.Job_domain,a.location) Avg_min_sal,b.Job_domain,b.Location,b.Expected_Salary_LPA
FROM MyPortfolio.dbo.Job_data a 
JOIN 
MyPortfolio.dbo.Job_data b
ON a.Job_domain=b.Job_domain and a.Location=b.Location
where b.Expected_Salary_LPA is null


--Updating the Expected salary with averages salary based on Job domain and location
UPDATE a
set a.Expected_Salary_LPA=b.Avg_min_sal
from MyPortfolio.dbo.Job_data a
inner join
(select Job_Domain,location,avg(Expected_Salary_LPA) over (partition by Job_Domain,location) Avg_min_sal from MyPortfolio.dbo.Job_data) as b
ON a.Job_Domain=b.Job_Domain and a.Location=b.Location
where a.Expected_Salary_LPA is null;


--Median salary based on job domain where the expected salary is NULL
SELECT a.Job_Domain,PERCENTILE_CONT(0.5)
within group(order by a.Expected_Salary_LPA)
over( partition by (a.Job_domain)) Median_min_sal,b.Job_domain,b.Expected_Salary_LPA
FROM MyPortfolio.dbo.Job_data a 
JOIN 
MyPortfolio.dbo.Job_data b
ON a.Job_domain=b.Job_domain
where b.Expected_Salary_LPA is null


--Updating the Expected salary with median salary based on Job domain
UPDATE a
set a.Expected_Salary_LPA=b.Median_sal
from MyPortfolio.dbo.Job_data a
inner join
(select Job_Domain,PERCENTILE_CONT(0.5)
within group(order by Expected_Salary_LPA)
over( partition by (Job_domain)) Median_sal
FROM MyPortfolio.dbo.Job_data) b
on a.Job_Domain=b.Job_Domain
where a.Expected_Salary_LPA is null


--Dropping Company_Stars column
alter table MyPortfolio.dbo.Job_data
drop column Company_Stars


--Updating Expected_Salary_LPA to 2 decimal places
Update MyPortfolio.dbo.Job_data
set Expected_Salary_LPA=ROUND(Expected_Salary_LPA,2); 
select Expected_Salary_LPA,ROUND(Expected_Salary_LPA,2) 
from MyPortfolio.dbo.Job_data;



--------------------------------------=-----------------------DATA EXPLORATION--------------------------------------------------------------------------


--Table visualisation
select *
from MyPortfolio.dbo.Job_data;

--Average Salary of different posts
select Post,round(avg(Expected_Salary_LPA),2) as Avg_Salary
from MyPortfolio.dbo.Job_data
group by Post
order by Avg_Salary desc;

--Average Salary of posts in different location
select Post,Location,round(avg(Expected_Salary_LPA),2) as Avg_Salary
from MyPortfolio.dbo.Job_data
group by Post,Location
order by Post,Avg_Salary desc;

--Average Salary of different Job domains
select Job_Domain,round(avg(Expected_Salary_LPA),2) as Avg_Salary
from MyPortfolio.dbo.Job_data
group by Job_Domain
order by Avg_Salary desc;

--Average Salary of Job domains in different location
select Job_Domain,Location,round(avg(Expected_Salary_LPA),2) as Avg_Salary
from MyPortfolio.dbo.Job_data
group by Job_Domain,Location
order by Avg_Salary desc;


--Number of job openings in different cities
select Location,count(Job_Domain) as Job_Openings
from MyPortfolio.dbo.Job_data
where Location not in ('India','Remote')
group by Location
order by Job_Openings desc;


--Number of job openings in different companies
select Company,count(Job_Domain) as Job_Openings
from MyPortfolio.dbo.Job_data
where Location not in ('India','Remote')
group by Company
order by Job_Openings desc;

--Minimum and maximum salary offered by each Job domain
select Job_Domain,max(Expected_Salary_LPA) as Maximum_salary_LPA,min(Expected_Salary_LPA) as Minimum_salary_LPA
from MyPortfolio.dbo.Job_data
group by Job_Domain
order by Maximum_salary_LPA desc,Minimum_salary_LPA;


--All engineering job openings
select * 
from MyPortfolio.dbo.Job_data
where Job_Domain like '%Engineer'