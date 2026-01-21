Project 1: Sales Forensic Audit & Revenue Recovery

Forensic Sales Audit: Recovering $4.8M in Potential Revenue
📌 Executive Summary
This project involved a deep-dive forensic audit of a $70M sales dataset. The investigation was triggered by universal losses across all product categories. Through systemic SQL analysis, I identified a massive billing variance (under-recording of sales) and a commercial discounting crisis. I proposed a data-driven recovery plan that transforms a $4.1M loss into a $653K profit.

🕵️ The Investigation (Step-by-Step)
Diagnosis: Used HAVING and subqueries to isolate regions and products where discounts exceeded the company average.

Systemic Error Detection: Calculated a billing_variance metric to prove that Sales_Amount was incorrectly recorded compared to Unit_Price * Quantity.

Leakage Audit: Ruled out theft/fraud by auditing Payment_Method and Sales_Channel, proving the loss was a system-wide logic failure rather than localized theft.

The Solution: Simulated a "What-If" scenario using a CASE statement to cap all discounts at 10%.

🛠️ Tech Stack
Language: SQL (DML, CTEs, Subqueries)

Logic: Conditional Aggregation, Impact Simulation

📈 Key Results
Total Loss Identified: $4,155,920.36

Billing Variance Identified: ~$66M discrepancy between recorded and expected sales.

Projected Recovery: $4,808,927 positive swing by implementing a 10% discount cap.

Project 2: Relational HR & Salary Analytics

Relational HR Analytics: Salary Growth & Pay Equity Audit
📌 Executive Summary
Using a large-scale relational database (300,000+ records), I built a comprehensive HR analytics engine to evaluate organizational health. The project focuses on the intersection of tenure, gender equity, and departmental spending. I utilized advanced SQL window functions to rank performance and identify "Salary Stagnation" points.

🔍 Key Insights Derived
Gender Pay Gap: Performed an "Adjusted Pay Gap" audit by comparing averages within specific departments rather than just company-wide.

Floor vs. Ceiling Analysis: Identified departments with "High Floors/Low Ceilings" (high entry pay, no growth) vs. "Low Floors/High Ceilings" (meritocratic/performance-heavy).

Stagnation Discovery: Correlated salary growth with tenure to find the exact year where employee raises typically plateau.

Data Infrastructure: Created VIEWS to simplify complex joins for HR stakeholders and management.

🛠️ Tech Stack
Language: SQL (Window Functions: RANK(), OVER(), PARTITION BY)

Database Architecture: Relational Joins (5+ tables), View Creation

Statistics: Measures of central tendency, range, and dispersion.

💡 Strategic Recommendations
Retention: Adjust pay scales in "Low Ceiling" departments to prevent senior-level attrition.

Equity: Targeted audits for the 'Research' and 'Development' departments to address identified pay variances.

