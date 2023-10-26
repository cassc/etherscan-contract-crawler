pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/v2/strategies/ITempleBaseStrategy.sol)

import { ITempleStrategy } from "contracts/interfaces/v2/strategies/ITempleStrategy.sol";

/**
 * @title Temple Base Strategy
 * @notice A special Temple Strategy which is eligable to transiently apply capital
 * into a very safe yield bearing protocol (eg DAI Savings Rate).
 * 
 * The Treasury Reserves Vault will have permission to pull back funds from this strategy
 * at any time, for example when another strategy wants to borrow funds.
 */
interface ITempleBaseStrategy {
    /**
     * @notice The latest checkpoint of each asset balance this strategy holds.
     *
     * @dev The asset value may be stale at any point in time, depending on the strategy. 
     * It may optionally implement `checkpointAssetBalances()` in order to update those balances.
     */
    function latestAssetBalances() external view returns (ITempleStrategy.AssetBalance[] memory assetBalances);

    /**
     * @notice The same as `borrowMax()` but for a pre-determined amount to borrow,
     * such that something upstream/off-chain can determine the amount.
     */
    function borrowAndDeposit(uint256 amount) external;

    /**
     * @notice When the TRV has a surplus of funds (over the configured buffer threshold)
     * it will transfer tokens to the base strategy, and call this function to apply
     * the new captial.
     */
    function trvDeposit(uint256 amount) external;

    /**
     * @notice The TRV is able to withdraw on demand in order to fund other strategies which 
     * wish to borrow from the TRV.
     * @dev It may withdraw less than requested if there isn't enough balance in the DSR.
     */
    function trvWithdraw(uint256 requestedAmount) external returns (uint256 amountWithdrawn);

}