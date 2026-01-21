SELECT * FROM sales_data_practice.sales_data;

SELECT
	Region,
    Product_Category,
    ROUND(SUM(Sales_Amount),2) AS total_sale_amount,
    ROUND(SUM(Sales_Amount) - SUM(Quantity_Sold * Unit_Cost),2) AS total_profit,
    ROUND(AVG(Discount)* 100.0,2) AS average_discount_pct,
    ROUND((SELECT AVG(Discount)
	FROM sales_data)*100.0,2) AS overall_average_discount
FROM sales_data
GROUP BY Region, Product_Category
HAVING AVG(Discount) > (SELECT AVG(Discount)
						FROM sales_data)
ORDER BY total_profit DESC ;

-- ALL AREAS MAKING LOSES
-- COULD BE SYSTEM ERROR NEED FURTHER INVESTIGATION
-- FIRST SEE WHICH SALES_REP ARE UNDERPERFORMING & MARK-UP %
-- BELOW, PERFORM TRANSACTION AUDIT

WITH basic_metrics AS (SELECT
					Sales_Rep,
					Product_ID,
					Unit_Price,
					Unit_Cost,
					Quantity_Sold,
					Sales_Amount,
					
					-- MARK_UP_PCT
					ROUND((Unit_Price - Unit_Cost) *100.0 / Unit_Cost,2) AS Markup_pct,
					
					-- LOSS TRANSACTIONS 1 = LOSS
					CASE WHEN Unit_Price < Unit_Cost THEN 1 ELSE 0 END AS underpriced_loss,
					
					-- WHAT SHOULD WE GET VS WHAT WE GET
					ROUND(Sales_Amount -(Unit_price * Quantity_Sold),2) AS biling_variance
				FROM sales_data)
SELECT
	Sales_Rep,
    ROUND(AVG(Markup_pct),2) AS average_markUp,
    SUM(underpriced_loss) AS loss_transactions,
    ROUND(SUM(biling_variance),2) AS total_biling_variance
FROM basic_metrics
GROUP BY Sales_Rep;

-- ALL Sales_Reps making losses 
-- no transactions has price less than cost
-- next, check payment methods 
-- to see if losses come from specific payment method,
-- if from cash, theft, otherwise, could be system error

WITH basic_metrics AS (SELECT
						Sales_Rep,
						Unit_Price,
						Unit_Cost,
						Quantity_Sold,
						Product_ID,
						Payment_Method,
						Sales_Amount AS recorded_sales,
						ROUND((Unit_Price * Quantity_Sold)* (1-Discount),2) AS expected_sales,
						ROUND(Sales_Amount - (Unit_Price * Quantity_Sold)* (1-Discount),2) AS _variance,
						ROUND(ROUND(Sales_Amount - (Unit_Price * Quantity_Sold)* (1-Discount),2)*100.0/
							 ROUND((Unit_Price * Quantity_Sold)* (1-Discount),2),2) AS variance_pct
					FROM sales_data)
-- in almost every transactions, recorded_sales are less then expected_sales
SELECT
	Payment_Method,
    ROUND(SUM(recorded_sales),2) AS total_recorded_sales,
    ROUND(SUM(expected_sales),2) AS total_expected_sales,
    ROUND(SUM(_variance),2) AS total_variance,
    ROUND(AVG(variance_pct),2) AS average_variance_pct
FROM basic_metrics
GROUP BY Payment_Method
ORDER BY total_variance ASC ;-- to see which method is making the most losses 

-- INTERPRETATION
-- ALL METHODS MAKING LOSSES EQUALLY
-- POINT OUT SYSTEM ERROR
-- NOW, THE REAL NUMBERS

WITH recalculated_table AS (
    SELECT
        Product_Category,
        ROUND(SUM(Quantity_Sold * Unit_Price * (1 - Discount)), 2) AS total_revenue,
        ROUND(SUM(Quantity_Sold * Unit_Cost), 2) AS total_cost
    FROM sales_data
    GROUP BY Product_Category
)
SELECT
    Product_Category,
    total_revenue,
    total_cost,
    ROUND(total_revenue - total_cost, 2) AS TRUE_profit,
    ROUND((total_revenue - total_cost) / total_cost, 2) AS TRUE_margin
FROM recalculated_table
ORDER BY TRUE_profit DESC;
-- EVEN WITH CORRECTED RECALCULATION, PRODUCTS ARE STILL MAKING LOSSES 
-- explains underlying discounting crisis


    
WITH basic_metrics AS (SELECT
						Customer_Type,
						Product_Category,
						Unit_price * (1- Discount) AS net_price,
						Unit_Cost,
						Quantity_Sold,
						Discount,
						Unit_price * (1- Discount) * Quantity_Sold AS revenue,
						Unit_Cost * Quantity_Sold AS cost,
						(Unit_price * (1- Discount) * Quantity_Sold) - (Unit_Cost * Quantity_Sold) AS profit,
                        CASE WHEN Unit_price * (1- Discount) * Quantity_Sold < Unit_Cost * Quantity_Sold THEN 1 ELSE 0 END AS loss_transaction
					 FROM sales_data)
SELECT
	Customer_Type,
    Product_Category,
    ROUND(AVG((revenue - cost) / cost),2) AS average_markup_pct,
    ROUND(AVG(Discount * 100.0),2) AS average_discount_pct,
    ROUND(SUM(profit) / SUM(revenue),2) AS true_profit_margin,
    SUM(loss_transaction) AS total_loss_transactions,
    ROUND(SUM( CASE WHEN loss_transaction = 1 THEN profit ELSE 0 END),2) AS total_amount_lost
FROM basic_metrics
GROUP BY Customer_Type, Product_Category ;

-- LOSING MONEY EQUALLY ON BOTH RETURNING AND NEW CUSTOMERS
-- ALTHOUGH MARK UP% IS POSITIVE, PROFIT MARGIN SHOWS NEGATIVE
-- DISCOUNTS ARE TAKING AWAY THE PROFITS
-- LOSING MONEY EQUALLY ON BOTH RETURNING AND NEW CUSTOMERS
-- LOTS OF DISCOUNTS ARE GIVEN TO BOTH ATTRACT NEW CUSTOMERS AND
-- TO RETAIN EXISTING CUSTOMERS
    
    -- Final Audit, sales channel --
           WITH basic_metrics AS (SELECT
						Sales_Channel,
						Customer_Type,
						Product_Category,
						Unit_price * (1- Discount) AS net_price,
						Unit_Cost,
						Quantity_Sold,
						Discount,
						Unit_price * (1- Discount) * Quantity_Sold AS revenue,
						Unit_Cost * Quantity_Sold AS cost,
						(Unit_price * (1- Discount) * Quantity_Sold) - (Unit_Cost * Quantity_Sold) AS profit,
                        CASE WHEN Unit_price * (1- Discount) * Quantity_Sold < Unit_Cost * Quantity_Sold THEN 1 ELSE 0 END AS loss_transaction
					 FROM sales_data)
SELECT
	Sales_Channel,
    ROUND(AVG((revenue - cost) / cost),2) AS average_markup_pct,
    ROUND(AVG(Discount * 100.0),2) AS average_discount_pct,
    ROUND(SUM(profit) / SUM(revenue),2) AS true_profit_margin,
    SUM(loss_transaction) AS total_loss_transactions,
    ROUND(SUM( CASE WHEN loss_transaction = 1 THEN profit ELSE 0 END),2) AS total_amount_lost
FROM basic_metrics
GROUP BY Sales_Channel ;      

-- same for sales channel
-- system failure as a whole

-- Recovery Plan Discount at 10%
WITH new_discounted_table AS (SELECT
								Product_ID,
								Product_Category,
								Unit_Price,
								Unit_Cost,
								Quantity_Sold,
                                Discount,
								CASE WHEN Discount > 0.1 THEN 0.1 ELSE Discount END AS new_discount
							FROM sales_data)
		SELECT
			Product_Category,
            ROUND(SUM(Unit_price * (1 - Discount) * Quantity_Sold),2) AS current_revenue,
            ROUND(SUM(Unit_price * (1 - new_discount) * Quantity_Sold),2) AS potential_revenue,
            ROUND(SUM(((Unit_price * (1 - Discount)) - Unit_Cost) * Quantity_Sold),2) AS current_profit,
            ROUND(SUM(((Unit_price * (1 - new_discount)) - Unit_Cost) * Quantity_Sold),2) AS potential_profit
        FROM new_discounted_table
        GROUP BY Product_Category;

-- NO BAD product problem, only math problem
-- average discount 15-20 % causing losses      
-- DISCOUNT 10% START TO SHOW PROFIT 
-- ORIGINALLY 4.1M LOSS TO 653K PROFIT