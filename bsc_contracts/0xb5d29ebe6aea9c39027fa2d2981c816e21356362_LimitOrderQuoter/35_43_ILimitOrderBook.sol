// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../LimitOrderBook.sol";

interface ILimitOrderBook {
    function totalOrdersPerAddress(address owner)
        external
        view
        returns (uint256);

    function placeLimitOrder(LimitOrderBook.LimitOrder[] calldata orderGroup)
        external
        payable
        returns (bytes32[] memory);

    function updateOrder(
        bytes32 orderId,
        uint128 price,
        uint128 quantity
    ) external payable;

    function cancelOrder(bytes32 orderId) external;

    function cancelOrders(bytes32[] memory orderIds) external;

    function getAllOrderIds(address owner)
        external
        view
        returns (bytes32[][] memory);

    function addressToOrderIds(address owner, bytes32 orderId)
        external
        view
        returns (LimitOrderBook.OrderType);

    function getLimitOrderById(bytes32 orderId)
        external
        view
        returns (LimitOrderBook.LimitOrder memory);

    function totalOrdersQuantity(bytes32 owner) external view returns (uint256);

    function getAllOrderIdsLength(address owner)
        external
        view
        returns (uint256);

    function getOrderIds(
        address owner,
        LimitOrderBook.OrderType targetOrderType,
        uint256 orderOffset,
        uint256 length
    ) external view returns (bytes32[] memory);

    function getTotalOrdersValue(address token) external view returns (uint256);

    function decreaseExecutionCredit(bytes32 orderId, uint128 amount) external;

    function increaseExecutionCredit(bytes32 orderId) external payable;
}