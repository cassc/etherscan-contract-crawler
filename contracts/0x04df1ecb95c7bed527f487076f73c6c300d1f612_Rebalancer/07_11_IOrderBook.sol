// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface IOrderBook {
    function nextOrderId() external view returns (uint64);

    function getOrder(uint64 orderId) external view returns (bytes32[3] memory, bool);

    /**
     * @dev   Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *        msg.sender must implement IMuxRebalancerCallback.
     * @param tokenId0      asset.id to be swapped out of the pool
     * @param tokenId1      asset.id to be swapped into the pool
     * @param rawAmount0    token 0 amount. decimals = erc20.decimals
     * @param maxRawAmount1 max token 1 that rebalancer is willing to pay. decimals = erc20.decimals
     * @param userData       max token 1 that rebalancer is willing to pay. decimals = erc20.decimals
     */
    function placeRebalanceOrder(
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0, // erc20.decimals
        uint96 maxRawAmount1, // erc20.decimals
        bytes32 userData
    ) external;

    function cancelOrder(uint64 orderId) external;
}