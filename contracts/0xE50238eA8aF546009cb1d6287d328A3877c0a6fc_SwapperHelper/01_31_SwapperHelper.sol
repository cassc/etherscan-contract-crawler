// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Swapper.sol";

contract SwapperHelper {
    function getOrders(
        address swapper,
        address user
    ) external view returns (uint256[] memory orderIds, Swapper.Order[] memory orders) {
        orders = Swapper(swapper).getOrders(user);
        orderIds = new uint256[](orders.length);

        uint256 orderId = 0;
        uint256 userOrders = 0;
        while (userOrders < orders.length) {
            (
                address sender,
                uint256 amountIn,
                uint256 minPriceX96,
                uint256 deadline,
                uint256 pushInfoIndex,
                Swapper.Pair memory pair
            ) = Swapper(swapper).orders(orderId);
            orderId++;
            Swapper.Order memory order = orders[userOrders];
            if (
                sender != order.sender ||
                amountIn != order.amountIn ||
                minPriceX96 != order.minPriceX96 ||
                deadline != order.deadline ||
                pushInfoIndex != order.pushInfoIndex ||
                pair.tokenIn != order.pair.tokenIn ||
                pair.tokenOut != order.pair.tokenOut
            ) {
                continue;
            }
            orderIds[userOrders++] = orderId - 1;
        }
    }
}