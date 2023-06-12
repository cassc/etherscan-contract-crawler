// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBGlobalFundingCycleMetadata.sol";

/// @custom:member global Data used globally in non-migratable ecosystem contracts.
/// @custom:member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
/// @custom:member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
/// @custom:member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
/// @custom:member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
/// @custom:member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
/// @custom:member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
/// @custom:member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
/// @custom:member allowMinting A flag indicating if minting tokens should be allowed during this funding cycle.
/// @custom:member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
/// @custom:member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
/// @custom:member holdFees A flag indicating if fees should be held during this funding cycle.
/// @custom:member preferClaimedTokenOverride A flag indicating if claimed tokens should always be prefered to unclaimed tokens when minting.
/// @custom:member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
/// @custom:member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
/// @custom:member metadata Metadata of the metadata, up to uint8 in size.
struct JBPayDataSourceFundingCycleMetadata {
    JBGlobalFundingCycleMetadata global;
    uint256 reservedRate;
    uint256 redemptionRate;
    uint256 ballotRedemptionRate;
    bool pausePay;
    bool pauseDistributions;
    bool pauseRedeem;
    bool pauseBurn;
    bool allowMinting;
    bool allowTerminalMigration;
    bool allowControllerMigration;
    bool holdFees;
    bool preferClaimedTokenOverride;
    bool useTotalOverflowForRedemptions;
    bool useDataSourceForRedeem;
    uint256 metadata;
}