--1. List all distinct items (No., Description) ever purchased.
/*SELECT 
    CASE 
        WHEN MAX(Buy_from_Vendor_No) = 'V0093' THEN 'V0093' else 'Other Vendor'
        END AS Is_Selected,
        ISnull(MAX(No), '') AS No,
        buy_from_Vendor_No,
    CAST(Description AS NVARCHAR(255)) AS Description,
    Location_Code,
    SUM(TRY_CAST(Quantity AS DECIMAL(18,2))) AS Total_Quantity
FROM dbo.Trofi_Data
GROUP BY 
    No, 
    buy_from_Vendor_No,
    CAST(Description AS NVARCHAR(255)), 
    Location_Code;
*/
--2. Find all transactions where Buy-from Vendor No. = 'V0093'.
   /* Select 
    No, 
    Description
    From dbo.Trofi_Data
    where buy_from_Vendor_No = 'V0093'
    */
--3. Get the total Qty By Base Unit purchased for each Unit of Measure Code.
/* SELECT 
    Case 
    WHEN GROUPING(Base_Unit_Of_Measure) = 1 THEN 'Total'
    Else isnull(Base_Unit_Of_Measure, 'Misc.') 
END As UOM,
SUM(TRY_CAST(Quantity As decimal(18,2))) AS Total_Quantity
From dbo.Trofi_Data
GROUp by   
Base_Unit_Of_Measure With ROLLUP */

--4. List the 10 most recent purchase transactions by Posting Date.
/*Select 
Top 10 *
From dbo.Trofi_Data
ORDER BY Posting_Date DESC */

--Clean Quantity data 
/*SELECT TOP 10
    No, 
    Description,
    Quantity AS Original_Quantity,
    TRY_CAST(
        REPLACE(
            TRIM(
                CASE 
                    -- Handle cases where Quantity is just a single dot '.'
                    WHEN TRIM(Quantity) = '.' THEN NULL
                    -- Remove trailing dot if present
                    WHEN TRIM(Quantity) LIKE '%.' THEN LEFT(TRIM(Quantity), LEN(TRIM(Quantity)) - 1)
                    ELSE TRIM(Quantity)
                END
            ),
            ',', ''
        ) AS DECIMAL(18,2)
    ) AS Clean_quantity
FROM dbo.Trofi_Data
WHERE 
    Quantity IS NOT NULL
    -- Exclude records that become 0, NULL, or empty after cleaning
    AND TRY_CAST(
        REPLACE(
            TRIM(
                CASE 
                    WHEN TRIM(Quantity) = '.' THEN NULL
                    WHEN TRIM(Quantity) LIKE '%.' THEN LEFT(TRIM(Quantity), LEN(TRIM(Quantity)) - 1)
                    ELSE TRIM(Quantity)
                END
            ),
            ',', ''
        ) AS DECIMAL(18,2)
    ) > 0
ORDER BY Clean_quantity DESC; */

--Count how many purchase documents exist per Location Code.
/*SELECT 
COUNT(Document_No) As Total_Documents,
isnull(Location_Code, 'N/A') AS Location_Code
From dbo.Trofi_Data
GROUP BY Location_Code
Order BY Total_Documents DESC*/

--Find all rows where Type = 'Item' and Quantity > 500.
/*SELECT
NO,
Description,
Qty_By_Base_Unit
FROM dbo.trofi_DATA
WHERE Qty_By_Base_Unit >= 500
Order by Qty_By_Base_Unit ASC;*/

--7. Which vendor supplied the most distinct items?
/*Select top 20
Buy_from_Vendor_No,
COUNT(Qty_By_Base_Unit) As Total_Qnty
FROM dbo.Trofi_Data
GROUP BY Buy_from_Vendor_No
ORDER BY Total_Qnty DESC;*/

--8. What are the top 10 items by total quantity purchased (in base units)?
/*
SELECT TOP 10
    [No],
    CAST(Description AS NVARCHAR(255)) AS Description,
    SUM(
        TRY_CAST(
            REPLACE(
                CASE 
                    WHEN TRIM(CAST(Qty_By_Base_Unit AS VARCHAR(50))) = '.' THEN NULL
                    WHEN TRIM(CAST(Qty_By_Base_Unit AS VARCHAR(50))) LIKE '%.' 
                     THEN LEFT(TRIM(CAST(Qty_By_Base_Unit AS VARCHAR(50))), LEN(TRIM(CAST(Qty_By_Base_Unit AS VARCHAR(50)))) - 1)
                    ELSE TRIM(CAST(Qty_By_Base_Unit AS VARCHAR(50)))
                END,
                ',', ''
            ) AS DECIMAL(18,2)
        )
    ) AS Total_Base_Qty
FROM dbo.Trofi_Data
GROUP BY 
    [No],
    CAST(Description AS NVARCHAR(255))
ORDER BY 
    Total_Base_Qty DESC;*/
    
--9. Find vendors who have supplied fewer than 3 distinct items (potential single-item/niche suppliers).
/*
Select
    Buy_from_Vendor_No,
    COUNT(DISTINCT No) AS Distinct_Item_Count
    from trofi_Data
    group by Buy_from_Vendor_No
    having COUNT(DISTINCT No) <=3
    order by Distinct_Item_Count ASC;*/

--10. For each location, find the single item purchased in the highest total quantity.
/*
WITH RankedItems AS (
    SELECT 
        Location_Code,
        [No],
        CAST(Description AS NVARCHAR(255)) AS Description,
        SUM(TRY_CAST(Quantity AS DECIMAL(18,2))) AS Total_Quantity,
        ROW_NUMBER() OVER (
            PARTITION BY Location_Code 
            ORDER BY SUM(TRY_CAST(Quantity AS DECIMAL(18,2))) DESC
        ) AS RowNum
    FROM dbo.Trofi_Data
    WHERE [Type] = 'Item' -- Filter for items only
    GROUP BY 
        Location_Code,
        [No],
        Unit_of_Measure_Code,
        CAST(Description AS NVARCHAR(255))
)
SELECT 
    Location_Code,
    [No],
    Description,
    Total_Quantity
FROM RankedItems
WHERE RowNum = 1
ORDER BY Total_Quantity DESC;
*/

--11. Which items have been purchased under more than one Unit of Measure Code (data consistency check)?
/*
WITH DistinctUOM AS (
    SELECT DISTINCT 
        [No],
        CAST(Description AS NVARCHAR(255)) AS Description,
        Unit_of_Measure_Code
    FROM dbo.Trofi_Data
    WHERE [Type] = 'Item'
      AND Unit_of_Measure_Code IS NOT NULL
)
SELECT 
    [No],
    Description,
    COUNT(Unit_of_Measure_Code) AS Distinct_UOM_Count,
    STRING_AGG(Unit_of_Measure_Code, ', ') AS Used_UOM_Codes
FROM DistinctUOM
GROUP BY 
    [No],
    Description
HAVING COUNT(Unit_of_Measure_Code) > 1
ORDER BY Distinct_UOM_Count DESC, [No];
*/
--12. Find documents (Document No.) that contain more than 5 line items — these are likely consolidated POs.

/*

SELECT 
    CAST(Document_No AS NVARCHAR(255)) AS Document_No,
    COUNT(*) AS Line_Item_Count
FROM dbo.Trofi_Data
WHERE [Type] = 'Item'
GROUP BY 
    CAST(Document_No AS NVARCHAR(255))
HAVING COUNT(*) > 5
ORDER BY Line_Item_Count DESC;
*/

--13. Calculate the average quantity per order line, grouped by Type.
/*
SELECT 
    CAST([Type] AS NVARCHAR(50)) AS Type_of,
    AVG(TRY_CAST(Quantity AS DECIMAL(18,4)))AS Average_Quantity
FROM dbo.Trofi_Data
WHERE [Type] IS NOT NULL
GROUP BY 
    CAST([Type] AS NVARCHAR(50))
ORDER BY 
    Average_Quantity DESC;

*/
 
--14. Find the month with the highest total quantity purchased across all items.


/*
SELECT TOP 5
    DATENAME(MONTH, Posting_Date) AS Month_Name,
    MONTH(Posting_Date) AS Month_Number,
    SUM(TRY_CAST(Quantity AS DECIMAL(18,2))) AS Total_Quantity
FROM dbo.Trofi_Data
WHERE [Type] = 'Item'
  AND Posting_Date IS NOT NULL
GROUP BY 
    DATENAME(MONTH, Posting_Date),
    MONTH(Posting_Date)
ORDER BY 
    Total_Quantity DESC;
*/
--15: Find the Top Vendor for Each Month
/*
 Select Top 5
    CAST(Buy_from_Vendor_No as varchar(50)) As Vendor_No,
    SUM(TRY_CAST(Quantity AS DECIMAL(18,2))) AS Total_Quantity
    from dbo.trofi_Data
    Where [type] = 'Item'
        And Buy_from_Vendor_No IS NOT NULL
    GROUP BY
    CAST(Buy_from_Vendor_No as varchar(50))
    ORDER BY
    Total_Quantity DESC:
*/

--16: Find Items Sold in Multiple Locations
/*
With Distinct_Item_Count AS (
    SELECT DISTINCT
    [No],
    TRY_CAST(Description AS varchar(MAX)) As Discription,
    Location_Code
    FROM
    dbo.Trofi_Data
    Where [Type] = 'Item'
    And Location_Code is not null
)
SELECT
    [No],
    Discription,
    COUNT(Location_Code) As Locations,
    STRING_AGG(Location_Code, ', ') AS Multiple
From Distinct_Item_Count
GROUP BY
    [No],
    Discription
    Having COUNT(Location_Code) >2
    ORDER BY Locations DESC
*/
-- 17: Find Multi-Source Items (Items Purchased from Multiple Vendors)
/*
With Distinct_Item_Count AS (
    Select Distinct
    [No],
    TRY_CAST(Description As VARCHAR(MAX)) As Description,
    Buy_from_Vendor_No
    From dbo.Trofi_Data
    Where [Type] = 'Item'
    AND Buy_from_Vendor_No IS NOT NULL
)
    Select
    [No],
    TRY_CAST(Description As VARCHAR(MAX)),
    COUNT(Buy_from_Vendor_No) As Vendor_No,
    STRING_AGG(Buy_from_Vendor_No, '/ ') As Vendor
    FROM Distinct_Item_Count
    GROUP BY
    [No],
    Description
    HAVING COUNT(Buy_from_Vendor_No) >1
    ORDER BY Vendor_No DESC
*/

-- 18: Identify Seasonal Demand Trends
use     
Trofi_Data
Go 
SELECT 
    [No] AS Item_No,
    CAST(Description AS NVARCHAR(255)) AS Description,
    
    -- Q1 Total (Months 1, 2, 3)
    SUM(CASE 
            WHEN MONTH(Posting_Date) IN (1, 2, 3) 
            THEN ABS(TRY_CAST(Quantity AS DECIMAL(18,2))) 
            ELSE 0 
        END) AS Q1_Total_Qty,
        
    -- Q2 Total (Months 4, 5, 6)
    SUM(CASE 
            WHEN MONTH(Posting_Date) IN (4, 5, 6) 
            THEN ABS(TRY_CAST(Quantity AS DECIMAL(18,2))) 
            ELSE 0 
        END) AS Q2_Total_Qty,
        
    -- Overall Total
    SUM(ABS(TRY_CAST(Quantity AS DECIMAL(18,2)))) AS Overall_Total_Qty

FROM dbo.Trofi_Data
WHERE LTRIM(RTRIM([Type])) = 'Item'
  AND Posting_Date IS NOT NULL
GROUP BY 
    [No],
    CAST(Description AS NVARCHAR(255))
HAVING 
    SUM(CASE WHEN MONTH(Posting_Date) IN (1, 2, 3) THEN ABS(TRY_CAST(Quantity AS DECIMAL(18,2))) ELSE 0 END) > 0
AND 
    SUM(CASE WHEN MONTH(Posting_Date) IN (4, 5, 6) THEN ABS(TRY_CAST(Quantity AS DECIMAL(18,2))) ELSE 0 END) > 0
ORDER BY 
    Overall_Total_Qty DESC;