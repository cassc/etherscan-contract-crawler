//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libraries/DataTypes.sol";
import "./IContango.sol";

enum OrderType {
    Limit,
    TakeProfit,
    StopLoss
}

struct OrderParams {
    PositionId positionId;
    int128 quantity;
    uint128 limitPrice; // in quote currency
    uint256 tolerance; // 0.003e4 = 0.3%
    int128 cashflow;
    Currency cashflowCcy;
    uint32 deadline;
    OrderType orderType;
}

struct Order {
    address owner;
    PositionId positionId;
    int256 quantity;
    uint256 limitPrice;
    uint256 tolerance;
    int256 cashflow;
    Currency cashflowCcy;
    uint256 deadline;
    OrderType orderType;
}

interface IOrderManagerEvents {

    event OrderPlaced(
        OrderId indexed orderId,
        PositionId indexed positionId,
        address indexed owner,
        int256 quantity,
        uint256 limitPrice,
        uint256 tolerance,
        int256 cashflow,
        Currency cashflowCcy,
        uint256 deadline,
        OrderType orderType,
        address placedBy
    );

    event OrderCancelled(OrderId indexed orderId);
    event OrderExecuted(OrderId indexed orderId, PositionId indexed positionId, uint256 keeperReward);

    event GasMultiplierSet(uint256 gasMultiplier);
    event GasTipSet(uint256 gasTip);

}

interface IOrderManagerErrors {

    error AboveMaxGasMultiplier(uint64 gasMultiplier); // 0x64d79f87
    error BelowMinGasMultiplier(uint64 gasMultiplier); // 0x7f732d9b
    error InvalidDeadline(uint256 deadline, uint256 blockTimestamp); // 0x8848019e
    error InvalidOrderType(OrderType orderType); // 0xf2bc1bb6
    error InvalidPrice(uint256 forwardPrice, uint256 limitPrice); // 0xaf608abb
    error InvalidQuantity(); // 0x524f409b
    error InvalidTolerance(uint256 tolerance); // 0x7ca28bcf
    error OrderDoesNotExist(OrderId orderId); // 0xbd8da02b
    error OrderAlreadyExists(OrderId orderId); // 0x086371d3
    error OrderExpired(OrderId orderId, uint256 deadline, uint256 blockTimestamp); // 0xc8105aba
    error OrderInvalidated(OrderId orderId); // 0xd10aebae
    error PositionDoesNotExist(PositionId positionId); // 0x80cc2277

}

interface IOrderManager is IOrderManagerEvents, IOrderManagerErrors, IContangoErrors {

    function placeOnBehalfOf(OrderParams calldata params, address onBehalfOf) external returns (OrderId orderId);

    function place(OrderParams calldata params) external returns (OrderId orderId);

    function cancel(OrderId orderId) external;

    function execute(OrderId orderId, ExecutionParams calldata execParams)
        external
        payable
        returns (PositionId positionId_, Trade memory trade_, uint256 keeperReward_);

    // ======== View ========

    function orders(OrderId orderId) external view returns (Order memory order);
    function hasOrder(OrderId orderId) external view returns (bool);
    function nativeToken() external view returns (IWETH9);
    function positionNFT() external view returns (PositionNFT);

    // ======== Admin ========

    function setGasMultiplier(uint64 gasMultiplier) external;
    function setGasTip(uint64 gasTip) external;

}