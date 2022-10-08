// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { Vault } from "../libraries/Vault.sol";

abstract contract NeuronThetaVaultStorageV1 {
    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;
    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;
    /// @notice Vault's state of the options sold and the timelocked option
    Vault.OptionState public optionState;
    Vault.CollateralUpdate internal collateralUpdate;
    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;
    /// @notice role in charge of weekly vault operations such as rollToNextOption and burnRemainingONTokens
    // no access to critical vault changes
    address public keeper;
    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;
    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;
    /// @notice Stores locked value of collateral on rollToNextOption, denominated in asset
    mapping(uint256 => uint256[]) public roundCollateralsValues;
    // Logic contract used to price options
    address public optionsPremiumPricer;
    // Logic contract used to select strike prices
    address public strikeSelection;
    // Premium discount on options we are selling (thousandths place: 000 - 999)
    uint256 public premiumDiscount;
    // Current onToken premium
    uint256 public currentONtokenPremium;
    // Last round id at which the strike was manually overridden
    uint16 public lastStrikeOverrideRound;
    // Price last overridden strike set to
    uint256 public overriddenStrikePrice;
    // Auction duration
    uint256 public auctionDuration;
    // Auction id of current option
    uint256 public optionAuctionID;
    // Auction bid token address
    address public auctionBiddingToken;
    // Auction bid token address
    uint8 public auctionBiddingTokenDecimals;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of NeuronThetaVaultStorage
// e.g. NeuronThetaVaultStorage<versionNumber>, so finally it would look like
// contract NeuronThetaVaultStorage is NeuronThetaVaultStorageV1, NeuronThetaVaultStorageV2
abstract contract NeuronThetaVaultStorage is NeuronThetaVaultStorageV1 {

}