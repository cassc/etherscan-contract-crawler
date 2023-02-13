// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ILimitOrderRouter {
    function refreshOrder(bytes32[] memory orderIds) external;

    function validateAndCancelOrder(bytes32 orderId)
        external
        returns (bool success);

    function executeLimitOrders(bytes32[] calldata orderIds) external;

    function confirmTransferOwnership() external;

    function transferOwnership(address newOwner) external;
}