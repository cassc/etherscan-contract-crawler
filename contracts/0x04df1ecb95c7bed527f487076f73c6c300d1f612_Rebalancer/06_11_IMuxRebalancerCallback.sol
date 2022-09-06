// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/**
 * @notice Any contract that calls IOrderBook#placeRebalanceOrder must implement this interface
 */
interface IMuxRebalancerCallback {
    /**
     * @notice Rebalancer.muxRebalanceCallback is called when Brokers calls IOrderBook#fillRebalanceOrder, where
     *         Rebalancer is `msg.sender` of IOrderBook#placeRebalanceOrder.
     *
     *         Rebalancer will get token0 and send token1 back to `msg.sender`.
     */
    function muxRebalanceCallback(
        address token0,
        address token1,
        uint256 rawAmount0,
        uint256 minRawAmount1,
        bytes32 data
    ) external;
}