SET @end   = DATE(NOW());
SET @start = DATE(NOW() - INTERVAL ${REPORT_INTERVAL_DAYS} DAY);

SELECT  CONCAT('REPORT FROM ', @start, ' TO ', @end) AS '';
SELECT  ROUND(SUM(`PreTaxCost`), 2) AS 'Total PreTaxCost',
        `ResourceGroup`
        FROM `azure-report`
        WHERE `UsageDateTime` >= @start
          AND `UsageDateTime` <= @end
        GROUP BY `ResourceGroup`
        HAVING SUM(`PreTaxCost`) > 0.01;

SELECT  'Cost by date' AS '';
SELECT  ROUND(SUM(`PreTaxCost`), 2) AS 'PreTaxCost',
        `ResourceGroup`,
        `MeterCategory`,
        `UsageDateTime`
        FROM `azure-report`
        WHERE `UsageDateTime` >= @start
          AND `UsageDateTime` <= @end
        GROUP BY `ResourceGroup`, `MeterCategory`, `UsageDateTime`
        HAVING SUM(`PreTaxCost`) > 0.01;
