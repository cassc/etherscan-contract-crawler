// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface ISwap {
    event LowstableTokenalance(address Token, uint256 balanceLeft);
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
    event EmergencyWithdrawComplete(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event FeeWithdraw(address indexed sender, uint256 commodityAmount, uint256 stableAmount);
    event ChainlinkFeedAddressChanged(address newFeedAddress);
    event withDrawAndDestroyed(
        address indexed sender,
        uint256 reserveCommodity,
        uint256 reserveStable,
        uint256 feeA,
        uint256 feeB
    );

    event UnitMultiplierUpdated(uint256);
}