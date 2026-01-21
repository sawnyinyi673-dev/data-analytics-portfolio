-- The current department of each employee
SELECT
	CONCAT(e.first_name, ' ', e.last_name) AS employee,
    d.dept_name
FROM employees e
INNER JOIN dept_emp de ON e.emp_no = de.emp_no
	AND de.to_date = '9999-01-01'
INNER JOIN departments d ON de.dept_no = d.dept_no ;
							-- 
                            
                            
-- Top 5 Highest-Paid Employees by Department and Gender(with average comparison)

WITH ranking_table AS (SELECT
	CONCAT(e.first_name, ' ', e.last_name) AS employee,
    e.gender,
    s.salary,
    d.dept_name,
    RANK() OVER(PARTITION BY D.dept_name ORDER BY s.salary DESC) AS ranking,
    AVG(salary) OVER(PARTITION BY d.dept_name) AS dept_avg, -- department average
			(SELECT AVG(salary)
			FROM salaries 
			WHERE to_date = '9999-01-01') AS company_avg 	-- company wide average
FROM employees e
INNER JOIN salaries s ON e.emp_no = s.emp_no
	AND s.to_date = '9999-01-01'
INNER JOIN dept_emp de ON e.emp_no = de.emp_no
	AND de.to_date = '9999-01-01'
INNER JOIN departments d ON de.dept_no = d.dept_no
ORDER BY dept_name , salary DESC)

SELECT
	employee,
    gender,
    salary,
    dept_name,
    dept_avg,
    company_avg
FROM ranking_table
WHERE ranking <= 5 ;
								-- 
                                
                                
-- Departments with average salary above 70,000
SELECT
	d.dept_name,
    AVG(s.salary) AS average_salary
FROM salaries s
JOIN dept_emp de ON s.emp_no = de.emp_no
	AND s.to_date = '9999-01-01' AND de.to_date = '9999-01-01'
JOIN departments d ON de.dept_no = d.dept_no
GROUP BY d.dept_name
HAVING AVG(s.salary) > 70000
ORDER BY average_salary DESC ;
								--
                                
                                
-- The most common job title for each department --
WITH dept_title_count AS (SELECT
							d.dept_name,
							t.title AS most_common_title,
							COUNT(title) AS title_count
						FROM titles t
						JOIN dept_emp de ON t.emp_no = de.emp_no
							AND de.to_date = '9999-01-01' AND t.to_date = '9999-01-01'
						JOIN departments d ON de.dept_no = d.dept_no
						GROUP BY d.dept_name, t.title
						ORDER BY title_count DESC),
	ranking AS (SELECT
					dept_name,
					most_common_title,
					title_count,
					RANK() OVER(PARTITION BY dept_name ORDER BY title_count DESC) AS ranking
				FROM dept_title_count)
SELECT
	dept_name,
    most_common_title,
    title_count
FROM ranking
WHERE ranking = 1 ;
							-- 
                            
                            
-- Employees who have changed departments more then 1 time --
SELECT
	de.emp_no,
    CONCAT(e.first_name, ' ', e.last_name) AS employee,
    COUNT(de.emp_no) AS dept_count
FROM dept_emp de
JOIN employees e ON de.emp_no = e.emp_no
GROUP BY 1,2
HAVING COUNT(de.emp_no) > 1;
									-- 
                                    
                                    
-- Calculating salary growth percentage for each employee
-- *FIRST SALARY AND CURRENT SALARY*
WITH first_salary AS (SELECT
							emp_no,
							salary AS first_salary
						FROM salaries
						WHERE (emp_no, from_date) IN (SELECT emp_no, MIN(from_date)
													FROM salaries
													GROUP BY emp_no)),
salary_growth_table AS (SELECT
							s.emp_no,
							first_salary,
							salary AS current_salary,
							salary - first_salary AS salary_growth,
							ROUND((salary - first_salary)* 100.0 / first_salary,2) AS growth_pct
						FROM salaries s
						JOIN first_salary fs ON s.emp_no = fs.emp_no
							AND s.to_date = '9999-01-01')
    
-- DEPARTMENTAL SALARY GROWTH COMPARISON
SELECT
	d.dept_name,
    ROUND(AVG(first_salary),2) AS average_first_salary,
    ROUND(AVG(current_salary),2) AS average_current_salary,
    ROUND(AVG(salary_growth_table.salary_growth),2) AS average_growth,
    ROUND(AVG(salary_growth_table.growth_pct),2) AS average_growth_pct
FROM salary_growth_table
JOIN dept_emp de ON salary_growth_table.emp_no = de.emp_no
	AND de.to_date = '9999-01-01'
JOIN departments d ON de.dept_no = d.dept_no
GROUP BY d.dept_name
ORDER BY average_growth_pct DESC ;

-- on absolute terms, all departmental average growth clustered around 19,000
-- on relative terms, HR has the highest growth with 43.4% and Sales, least, 28.74%
-- interestingly, sales, marketing and finance are at the bottom of this salary growth pct
-- question3 shows those departments have highest average salary
-- meaning, Finance, Marketing and Sales have the highest base/first salary but low growth
												--

-- GENERAL SALARY DISTRIBUTION ANALYSIS
WITH  summary_stats AS (SELECT
							d.dept_name,
							COUNT(de.emp_no) AS employee_count,
							ROUND(AVG(s.salary),2) AS avg_salary,
							MAX(s.salary) AS max_salary,
							MIN(s.salary) AS min_salary,
							MAX(s.salary) - MIN(s.salary) AS salary_range,
							ROUND(STDDEV(s.salary),2) AS salary_dispersion,
							ROUND(STDDEV(s.salary)* 100.0 / AVG(s.salary),2) AS dispersion_pct,
							ROUND((SELECT AVG(salary)
							FROM salaries
							WHERE to_date = '9999-01-01'),2) AS company_average
						FROM salaries s
						JOIN dept_emp de ON s.emp_no = de.emp_no AND s.to_date = '9999-01-01' AND de.to_date = '9999-01-01'
						JOIN departments d ON de.dept_no = d.dept_no
						GROUP BY d.dept_name)
SELECT
	dept_name,
    employee_count,
    avg_salary,
    min_salary,
    salary_range,
    salary_dispersion,
    dispersion_pct,
    company_average,
    (avg_salary - company_average) AS difference
FROM summary_stats
ORDER BY difference DESC ;
-- ALL DEPARTMENTS SALARY MOVE AROUND 20 - 24% OF AVERAGE, MODERATE AMOUNT
-- WIDE SALARY RANGE, PAY GAP BEWTWEEN HIGHEST AND LOWEST
-- ALTHOUGH ABOVE DEPARTMENTS HAVE HIGH SALARY GROWTH, AVERAGE SALARY IS BELOW COMPANY AVERAGE
-- MEANING MOST SALARY BUDGET GOES TO SALES, MARKETING AND FINANCE
-- LEADING TO POTENTIAL PAY CRISIS


-- YEARLY SALARY TREND
-- disclaimer
-- employee dataset having row by row annual salary allows me to calculate yearly salary average.
-- however year(to_date) is a reliable near-complete estimation, since it's a snap shot of a salary for a specific year, excluding year-round salary change.
SELECT
	YEAR(to_date) AS fiscal_year,
    AVG(salary) AS average_salary
FROM salaries
GROUP BY 1
ORDER BY fiscal_year ;
										--
                                        
                                        
-- Departments with the most gender diversity (the count of male to female employees per department)
SELECT
	d.dept_name,
    SUM( CASE WHEN e.gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM( CASE WHEN e.gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    ROUND(SUM( CASE WHEN e.gender = 'F' THEN 1 ELSE 0 END) * 100.0 / COUNT(e.gender),2) AS female_pct
FROM employees e
JOIN dept_emp de ON e.emp_no = de.emp_no
	AND de.to_date = '9999-01-01'
JOIN departments d ON de.dept_no = d.dept_no
GROUP BY d.dept_name;
-- ALL DEPARTMENTS, FEMALE EMPLOYEE CONTRIBUTION OF 40%
-- PROPORTIONATE GENDER DISTRIBUTION 1.5 : 1
										--					

-- DEPARTMENTAL GENDER PAY COMPARISON 
WITH departmental_gender_pay AS (SELECT
									d.dept_name,
									AVG(CASE WHEN e.gender = 'M' THEN s.salary END) AS average_male_salary,
									AVG(CASE WHEN e.gender = 'F' THEN s.salary END) AS average_female_salary
								FROM salaries s
								JOIN employees e ON s.emp_no = e.emp_no
									AND s.to_date = '9999-01-01'
								JOIN dept_emp de ON s.emp_no = de.emp_no
									AND de.to_date = '9999-01-01'
								JOIN departments d ON de.dept_no = d.dept_no
								GROUP BY d.dept_name)
SELECT
	dept_name,
    ROUND(average_male_salary,2) AS avg_male_salary,
    ROUND(average_female_salary,2) AS avg_female_salary,
    ROUND(average_male_salary - average_female_salary,2) AS gender_pay_gap,
    ROUND((average_male_salary - average_female_salary) * 100.0 / average_male_salary,2) AS pay_gap_pct,
    CASE
		WHEN average_male_salary - average_female_salary > 0 THEN 'male'
		ELSE 'female'
	END AS gender_dominance
FROM departmental_gender_pay ;
-- no gender pay gap
								--  
                                
                                
-- Each department manager’s average managed salary
SELECT 
    d.dept_name,
    CONCAT(e.first_name, ' ', e.last_name) AS current_manager,
    ROUND(AVG(s.salary), 2) AS avg_managed_salary,
    COUNT(de.emp_no) AS team_count
FROM departments d
JOIN dept_manager dm ON d.dept_no = dm.dept_no 
	AND dm.to_date = '9999-01-01'
JOIN employees e     ON dm.emp_no = e.emp_no
JOIN dept_emp de     ON d.dept_no = de.dept_no 
	AND de.to_date = '9999-01-01'
JOIN salaries s      ON de.emp_no = s.emp_no  
	AND s.to_date = '9999-01-01'
GROUP BY d.dept_name, current_manager;
					-- 
                    
                    
-- Creating a view of current employees with salary info.
CREATE VIEW current_employee_salaries AS
SELECT 
    e.emp_no,
    e.first_name,
    e.last_name,
    d.dept_name,
    s.salary
FROM employees e
JOIN salaries s ON e.emp_no = s.emp_no AND s.to_date = '9999-01-01'
JOIN dept_emp de ON e.emp_no = de.emp_no AND de.to_date = '9999-01-01'
JOIN departments d ON de.dept_no = d.dept_no;
										--
									
-- employees who left
SELECT
	d.dept_name,
    COUNT(DISTINCT de.emp_no) AS employee_count
FROM dept_emp de
JOIN departments d ON de.dept_no = d.dept_no
WHERE de.to_date != '9999-01-01'
GROUP BY d.dept_name
ORDER BY employee_count DESC ;


-- EMPLOYEE TURNOVER ANALYSIS
SELECT
	d.dept_name,
    COUNT(DISTINCT de.emp_no) AS employee_count,
    COUNT(DISTINCT CASE WHEN de.to_date != '9999-01-01' THEN de.emp_no END) AS left_employees,
     ROUND(COUNT(DISTINCT CASE WHEN de.to_date != '9999-01-01' THEN de.emp_no END) * 100.0 /
     COUNT(DISTINCT de.emp_no),2) AS turnover_pct
FROM dept_emp de
JOIN departments d ON de.dept_no = d.dept_no
GROUP BY d.dept_name ;
									--
                                    
                                    
-- Basic Info: Name and Department.
-- The Percentile: Their CUME_DIST() within their department (formatted as a 0-100 score).
-- The Group: Which Quartile (NTILE(4)) they fall into based on salary.
-- The Comparison: The Average Salary of their specific department (to see if they are above or below the dept average).
-- The Gap: The difference between their salary and the highest salary in that department.

SELECT
	CONCAT(first_name, ' ', last_name) AS employee,
    salary,
    dept_name,
    ROUND(CUME_DIST() OVER(PARTITION BY dept_name ORDER BY salary DESC)*100.0,2) AS pct_rank,
    NTILE(4) OVER(PARTITION BY dept_name ORDER BY salary DESC) AS salary_bucket,
    AVG(salary) OVER(PARTITION BY dept_name) AS dept_average,
      MAX(salary) OVER(PARTITION BY dept_name) AS dept_highest,
    salary - MAX(salary) OVER(PARTITION BY dept_name) AS salary_difference
FROM current_employee_salaries
ORDER BY dept_name, salary DESC ;
