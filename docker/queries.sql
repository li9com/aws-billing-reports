SET @end   = DATE_FORMAT(NOW(), '%Y-%m-%d 00:00:00');
SET @start = DATE_FORMAT(NOW() - INTERVAL ${REPORT_INTERVAL_DAYS} DAY, '%Y-%m-%d 00:00:00');

SELECT  CONCAT('REPORT FROM ', @start, ' TO ', @end) AS '';
SELECT  ROUND(SUM(`unblendedCost`), 2) AS 'Total unblended cost',
        `LinkedAccountId` AS 'AccountID'
        FROM report
        WHERE `UsageStartDate` >= @start
          AND `UsageEndDate`   <= @end
        GROUP BY `LinkedAccountId`;

\! echo "Cost by service"
SELECT  ROUND(SUM(`unblendedCost`), 2) cost,
        `usageType`,
        `availabilityZone` AS 'AZ',
        `LinkedAccountId` AS 'AccountID'
        FROM report
        WHERE `UsageStartDate` >= @start
          AND `UsageEndDate`   <= @end
        GROUP BY `usageType`,`availabilityZone`, `LinkedAccountId`
        HAVING SUM(`unblendedCost`) > 0.01;

\! echo "Cost by owner"
SELECT  ROUND(SUM(`UnBlendedCost`), 2) AS cost,
        `aws:createdBy`,
        `user:Name` AS 'tag:Name',
        `LinkedAccountId` AS 'AccountID'
        FROM report
        WHERE `UsageStartDate` >= @start
          AND `UsageEndDate`   <= @end
        GROUP BY `aws:createdBy`, `user:Name`, `LinkedAccountId`
        HAVING SUM(`UnBlendedCost`) > 0.01;

\! echo "Cost by date"
SELECT  ROUND(SUM(`unblendedCost`), 2) cost,
        DATE(`UsageStartDate`),
        `LinkedAccountId` AS 'AccountID'
        FROM report
        WHERE `UsageStartDate` >= @start
          AND `UsageEndDate`   <= @end
        GROUP BY DATE(`UsageStartDate`), `LinkedAccountId`
        HAVING SUM(`unblendedCost`) > 0.01;
