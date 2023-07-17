// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IPool {
    event Swapped(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut,
        uint256 isSale
    );
    event LiquidityAdded(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event LiquidityRemoved(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event TradeFeeChanged(uint256 newTradeFee);
    event ComDexAdminChanged(address newAdmin);
    event EmergencyWithdraw(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event FeeWithdraw(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event FeedAddressesChanged(address newCommodityFeed, address newStableFeed);
    event withDrawAndDestroyed(
        address indexed sender,
        uint256 reserveCommodity,
        uint256 reserveStable,
        uint256 feeA,
        uint256 feeB
    );

    event UnitMultiplierUpdated(uint256);
    event BuySpotDifferenceUpdated(uint256);
    event SellSpotDifferenceUpdated(uint256);
}