//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @dev TermRepoTokenConfig represents key metadata associated with a Term Repo Token
struct TermRepoTokenConfig {
    /// @dev The date and time at which the Term Repo associated with this Term Repo Token comes due
    uint256 redemptionTimestamp;
    /// @dev The purchase token in which this Term Repo Token is denominated and is redeemable for
    address purchaseToken;
    /// @dev A list of collateral token addresses backing a Term Repo associated with this Term Repo Token
    address[] collateralTokens;
    /// @dev A list of the maintenance margin ratios applied to each eligible collateral token
    uint256[] maintenanceCollateralRatios;
}