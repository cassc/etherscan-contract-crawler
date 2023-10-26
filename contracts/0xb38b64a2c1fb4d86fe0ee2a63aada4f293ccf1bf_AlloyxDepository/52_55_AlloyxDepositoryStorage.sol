// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IAlloyxVault} from "../../external/alloyx/IAlloyxVault.sol";
import {IUXDController} from "../../core/IUXDController.sol";
import {IDepository} from "../IDepository.sol";

abstract contract AlloyxDepositoryStorage is IDepository {

    /// @dev Rage senior vault address
    IAlloyxVault public vault;

    /// @dev UXDController address
    IUXDController public controller;

    /// @dev The asset backing managed by this depository
    address public assetToken;

    /// @dev The redeemable managed by this depository
    address public redeemable;

    /// @dev Max amount of redeemable depository can manage
    uint256 public redeemableSoftCap;

    /// @dev Amount that can be redeemed. In redeemable decimals
    uint256 public redeemableUnderManagement;

    /// @dev Total amount deposited - amount withdrawn. In assetToken decimals
    uint256 public netAssetDeposits;

    /// @dev PnL that has be claimed/withdrawn
    uint256 public realizedPnl; // make this a function
}