// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { Vault } from "../libraries/Vault.sol";
import { INeuronPool } from "../../common/interfaces/INeuronPool.sol";

abstract contract NeuronCollateralVaultStorageV1 {
    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;
    /// @notice On every round's close, the pricePerShare value of an nTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;
    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    mapping(address => bool) public vaultSupportedTokens;
    /// @notice Vault's parameters like cap, decimals
    Vault.CollateralVaultParams public vaultParams;
    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.CollateralVaultState public vaultState;
    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;
    /// @notice role in charge of weekly vault operations such as rollToNextOption and burnRemainingONTokens
    // no access to critical vault changes
    address public keeper;
    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;
    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;
    /// @notice NeuronPool used as collateral contract
    INeuronPool public collateralToken;
    uint256 public lastQueuedWithdrawAmount;
    // When the vault is disabled it will allow to withdraw only with one token
    address disabledWithdrawalToken;
    // Amount of disabledWithdrawalToken for 1 vault share
    uint256 disabledPricePerShare;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of NeuronThetaVaultStorage
// e.g. NeuronThetaVaultStorage<versionNumber>, so finally it would look like
// contract NeuronThetaVaultStorage is NeuronThetaVaultStorageV1, NeuronThetaVaultStorageV2
abstract contract NeuronCollateralVaultStorage is NeuronCollateralVaultStorageV1 {

}