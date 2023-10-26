// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface to a Collateral Liquidation Receiver
 */
interface ICollateralLiquidationReceiver {
    /**
     * @notice Callback on collateral liquidated
     * @dev Pre-conditions: 1) proceeds were transferred, and 2) transferred amount >= proceeds
     * @param liquidationContext Liquidation context
     * @param proceeds Liquidation proceeds in currency tokens
     */
    function onCollateralLiquidated(bytes calldata liquidationContext, uint256 proceeds) external;
}