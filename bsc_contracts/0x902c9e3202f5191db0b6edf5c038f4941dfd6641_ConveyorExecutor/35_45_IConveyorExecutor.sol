// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../LimitOrderBook.sol";
import "../SandboxLimitOrderBook.sol";
import "../SandboxLimitOrderRouter.sol";

interface IConveyorExecutor {
    function executeTokenToWethOrders(LimitOrderBook.LimitOrder[] memory orders)
        external
        returns (uint256, uint256);

    function executeTokenToTokenOrders(
        LimitOrderBook.LimitOrder[] memory orders
    ) external returns (uint256, uint256);

    function executeSandboxLimitOrders(
        SandboxLimitOrderBook.SandboxLimitOrder[] memory orders,
        SandboxLimitOrderRouter.SandboxMulticall calldata calls
    ) external;

    function lastCheckIn(address account) external view returns (uint256);
}