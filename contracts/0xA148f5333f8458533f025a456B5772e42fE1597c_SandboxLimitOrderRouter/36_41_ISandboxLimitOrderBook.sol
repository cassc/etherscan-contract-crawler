// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../SandboxLimitOrderRouter.sol";
import "../SandboxLimitOrderBook.sol";

interface ISandboxLimitOrderBook {
    function totalOrdersPerAddress(address owner)
        external
        view
        returns (uint256);

    function executeOrdersViaSandboxMulticall(
        SandboxLimitOrderRouter.SandboxMulticall calldata sandboxMulticall
    ) external;

    function getSandboxLimitOrderRouterAddress()
        external
        view
        returns (address);

    function cancelOrder(bytes32 orderId) external;

    function getSandboxLimitOrderById(bytes32 orderId)
        external
        view
        returns (SandboxLimitOrderBook.SandboxLimitOrder memory);

    function updateSandboxLimitOrder(
        bytes32 orderId,
        uint128 amountInRemaining,
        uint128 amountOutRemaining
    ) external payable;

    function validateAndCancelOrder(bytes32 orderId) external returns (bool);

    function getAllOrderIdsLength(address owner)
        external
        view
        returns (uint256);

    function getOrderIds(
        address owner,
        SandboxLimitOrderBook.OrderType targetOrderType,
        uint256 orderOffset,
        uint256 length
    ) external view returns (bytes32[] memory);

    function addressToOrderIds(address owner, bytes32 orderId)
        external
        view
        returns (SandboxLimitOrderBook.OrderType);

    function placeSandboxLimitOrder(
        SandboxLimitOrderBook.SandboxLimitOrder[] calldata orderGroup
    ) external payable returns (bytes32[] memory);

    function totalOrdersQuantity(bytes32 owner) external view returns (uint256);

    function refreshOrder(bytes32[] memory orderIds) external;

    function getTotalOrdersValue(address token) external view returns (uint256);

    function decreaseExecutionCredit(bytes32 orderId, uint128 amount) external;

    function increaseExecutionCredit(bytes32 orderId) external payable;
}