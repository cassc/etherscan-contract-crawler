// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IBook.sol";
import "./IPairsManager.sol";
import "./ILimitOrder.sol";
import "./ITrading.sol";

interface ITradingChecker {

    enum Refund {
        NO, SWITCH, PAIR_STATUS, AMOUNT_IN, USER_PRICE, MIN_NOTIONAL_USD, MAX_NOTIONAL_USD,
        MAX_LEVERAGE, TP, SL, PAIR_OI, OPEN_LOST, SYSTEM, FEED_DELAY
    }

    function checkTp(
        bool isLong, uint takeProfit, uint entryPrice, uint leverage_10000, uint maxTakeProfitP
    ) external pure returns (bool);

    function checkSl(bool isLong, uint stopLoss, uint entryPrice) external pure returns (bool);

    function checkLimitOrderTp(ILimitOrder.LimitOrder memory order) external view;

    function openLimitOrderCheck(IBook.OpenDataInput calldata data) external view;

    function executeLimitOrderCheck(
        ILimitOrder.LimitOrder memory order, uint256 marketPrice
    ) external view returns (bool result, uint96 openFee, uint96 executionFee, Refund refund);

    function checkMarketTradeTp(ITrading.OpenTrade memory) external view;

    function openMarketTradeCheck(IBook.OpenDataInput calldata data) external view;

    function marketTradeCallbackCheck(
        ITrading.PendingTrade memory pt, uint256 marketPrice
    ) external view returns (bool result, uint96 openFee, uint96 executionFee, uint256 entryPrice, Refund refund);

    function executeLiquidateCheck(
        ITrading.OpenTrade memory ot, uint256 marketPrice, uint256 closePrice
    ) external view returns (bool needLiq, int256 pnl, int256 fundingFee, uint256 closeFee);
}