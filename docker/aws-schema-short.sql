CREATE  TABLE IF NOT EXISTS `aws-report` (
  `InvoiceID` VARCHAR(255),
  `PayerAccountId` VARCHAR(255),
  `LinkedAccountId` VARCHAR(255),
  `RecordType` VARCHAR(255),
  `RecordId` VARCHAR(255),
  `ProductName` VARCHAR(255),
  `RateId` VARCHAR(255),
  `SubscriptionId` VARCHAR(255),
  `PricingPlanId` VARCHAR(255),
  `UsageType` VARCHAR(255),
  `Operation` VARCHAR(255),
  `AvailabilityZone` VARCHAR(255),
  `ReservedInstance` VARCHAR(255),
  `ItemDescription` VARCHAR(255),
  `UsageStartDate` DATETIME,
  `UsageEndDate` DATETIME,
  `UsageQuantity` FLOAT,
  `BlendedRate` FLOAT,
  `BlendedCost` FLOAT,
  `UnBlendedRate` FLOAT,
  `UnBlendedCost` FLOAT,
  `ResourceId` VARCHAR(255),
  `aws:createdBy` VARCHAR(255),
  `user:Name` VARCHAR(255)
)
