//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20Metadata as IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

import "../libraries/DataTypes.sol";
import "../interfaces/IOrderManager.sol";

struct LinkedOrderParams {
    uint128 limitPrice; // in quote currency
    uint128 tolerance; // 0.003e4 = 0.3%
    Currency cashflowCcy;
    uint32 deadline;
    OrderType orderType;
}

struct EIP2098Permit {
    uint256 amount;
    uint256 deadline;
    bytes32 r;
    bytes32 vs;
}

interface IMaestro is IContangoErrors, IOrderManagerErrors, IVaultErrors {

    error InvalidCashflow();
    error InsufficientPermitAmount(uint256 required, uint256 actual);
    error MismatchingPositionId(OrderId orderId1, OrderId orderId2);
    error NotNativeToken(IERC20 token);

    function contango() external view returns (IContango);
    function orderManager() external view returns (IOrderManager);
    function vault() external view returns (IVault);
    function positionNFT() external view returns (PositionNFT);
    function nativeToken() external view returns (IWETH9);

    // =================== Funding primitives ===================

    function deposit(IERC20 token, uint256 amount) external returns (uint256);

    function depositNative() external payable returns (uint256);

    function depositWithPermit(IERC20Permit token, EIP2098Permit calldata permit) external returns (uint256);

    function depositWithPermit2(IERC20 token, EIP2098Permit calldata permit) external returns (uint256);

    function withdraw(IERC20 token, uint256 amount, address to) external returns (uint256);

    function withdrawNative(uint256 amount, address to) external returns (uint256);

    // =================== Trading actions ===================

    function trade(TradeParams calldata tradeParams, ExecutionParams calldata execParams) external returns (PositionId, Trade memory);

    function depositAndTrade(TradeParams calldata tradeParams, ExecutionParams calldata execParams)
        external
        payable
        returns (PositionId, Trade memory);

    function depositAndTradeWithPermit(TradeParams calldata tradeParams, ExecutionParams calldata execParams, EIP2098Permit calldata permit)
        external
        returns (PositionId, Trade memory);

    function tradeAndWithdraw(TradeParams calldata tradeParams, ExecutionParams calldata execParams, address to)
        external
        returns (PositionId positionId, Trade memory trade_, uint256 amount);

    function tradeAndWithdrawNative(TradeParams calldata tradeParams, ExecutionParams calldata execParams, address to)
        external
        returns (PositionId positionId, Trade memory trade_, uint256 amount);

    function tradeAndLinkedOrder(
        TradeParams calldata tradeParams,
        ExecutionParams calldata execParams,
        LinkedOrderParams memory linkedOrderParams
    ) external payable returns (PositionId positionId, Trade memory trade_, OrderId linkedOrderId);

    function tradeAndLinkedOrders(
        TradeParams calldata tradeParams,
        ExecutionParams calldata execParams,
        LinkedOrderParams memory linkedOrderParams1,
        LinkedOrderParams memory linkedOrderParams2
    ) external payable returns (PositionId positionId, Trade memory trade_, OrderId linkedOrderId1, OrderId linkedOrderId2);

    function depositTradeAndLinkedOrder(
        TradeParams calldata tradeParams,
        ExecutionParams calldata execParams,
        LinkedOrderParams memory linkedOrderParams
    ) external payable returns (PositionId positionId, Trade memory trade_, OrderId linkedOrderId);

    function depositTradeAndLinkedOrderWithPermit(
        TradeParams calldata tradeParams,
        ExecutionParams calldata execParams,
        LinkedOrderParams memory linkedOrderParams,
        EIP2098Permit calldata permit
    ) external returns (PositionId positionId, Trade memory trade_, OrderId linkedOrderId);

    function depositTradeAndLinkedOrders(
        TradeParams calldata tradeParams,
        ExecutionParams calldata execParams,
        LinkedOrderParams memory linkedOrderParams1,
        LinkedOrderParams memory linkedOrderParams2
    ) external payable returns (PositionId positionId, Trade memory trade_, OrderId linkedOrderId1, OrderId linkedOrderId2);

    function depositTradeAndLinkedOrdersWithPermit(
        TradeParams calldata tradeParams,
        ExecutionParams calldata execParams,
        LinkedOrderParams memory linkedOrderParams1,
        LinkedOrderParams memory linkedOrderParams2,
        EIP2098Permit calldata permit
    ) external returns (PositionId positionId, Trade memory trade_, OrderId linkedOrderId1, OrderId linkedOrderId2);

    function place(OrderParams memory params) external returns (OrderId orderId);

    function placeLinkedOrder(PositionId positionId, LinkedOrderParams memory params) external returns (OrderId orderId);

    function placeLinkedOrders(
        PositionId positionId,
        LinkedOrderParams memory linkedOrderParams1,
        LinkedOrderParams memory linkedOrderParams2
    ) external returns (OrderId linkedOrderId1, OrderId linkedOrderId2);

    function depositAndPlace(OrderParams memory params) external payable returns (OrderId orderId);

    function depositAndPlaceWithPermit(OrderParams memory params, EIP2098Permit calldata permit) external returns (OrderId orderId);

    function cancel(OrderId orderId) external;

    function cancel(OrderId orderId1, OrderId orderId2) external;

    function cancelReplaceLinkedOrder(OrderId cancelOrderId, LinkedOrderParams memory newLinkedOrderParams)
        external
        returns (OrderId newLinkedOrderId);

    function cancelReplaceLinkedOrders(
        OrderId cancelOrderId1,
        OrderId cancelOrderId2,
        LinkedOrderParams memory newLinkedOrderParams1,
        LinkedOrderParams memory newLinkedOrderParams2
    ) external returns (OrderId newLinkedOrderId1, OrderId newLinkedOrderId2);

    function cancelAndWithdraw(OrderId orderId, address to) external returns (uint256);

    function cancelAndWithdrawNative(OrderId orderId, address to) external returns (uint256);

}