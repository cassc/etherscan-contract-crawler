// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {OrderTypes} from "../../libraries/OrderTypes.sol";

interface TheUnemetaExchange {
    function matchSellerOrdersWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchSellerOrders(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external;

    function matchesBuyerOrder(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external;
}