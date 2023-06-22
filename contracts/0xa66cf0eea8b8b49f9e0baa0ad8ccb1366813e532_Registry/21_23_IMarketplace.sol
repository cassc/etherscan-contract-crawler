// SPDX-License-Identifier: MIT
// Creator: Nullion Labs

pragma solidity 0.8.11;

import '../lib/OrderInterface.sol';

interface IMarketplace {
    function fillOrder(
        OrderInterface.Order memory order,
        bytes memory signature,
        address buyer
    ) external;

    function cancelOrder(OrderInterface.Order memory order, bytes memory signature) external;
}