// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Interface for OrderBook
 */
interface IOrderbook {
    struct Order {
        address maker;
        uint256 amount;
        uint256 remAmount;
        uint256 amountWithFee;
        uint256 createdAt;
        uint256 updatedAt;
        OrdStatus status;
    }

    enum OrdStatus {
        PENDING,
        FILLED,
        CANCELLED
    }

    function placeBuyOrder(uint256 amountOfBaseToken) external;

    function placeSellOrder(uint256 amountOfTradeToken) external;

    event PlaceBuyOrder(
        uint256 orderId,
        address sender,
        uint256 price,
        uint256 amountOfBaseToken
    );
    event PlaceSellOrder(
        uint256 orderId,
        address sender,
        uint256 price,
        uint256 amountOfTradeToken
    );
    event CancelledBuyOrder(
        uint256 orderId,
        address sender,
        uint256 price,
        uint256 amountReceived
    );
    event CancelledSellOrder(
        uint256 orderId,
        address sender,
        uint256 price,
        uint256 amountReceived
    );
}