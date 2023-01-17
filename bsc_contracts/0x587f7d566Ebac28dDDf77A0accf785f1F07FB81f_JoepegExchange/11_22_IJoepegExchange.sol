// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICurrencyManager} from "./ICurrencyManager.sol";
import {IExecutionManager} from "./IExecutionManager.sol";

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IJoepegBuyBatcher {
    struct Trade {
        OrderTypes.TakerOrder takerBid;
        OrderTypes.MakerOrder makerAsk;
    }

    function batchBuyWithAVAXAndWAVAX(Trade[] calldata trades) external payable;

    function batchBuyWithAVAXAndWAVAXIgnoringExpiredAsks(
        Trade[] calldata trades
    ) external payable returns (bool[] memory transferStatus);
}

interface IJoepegExchange is IJoepegBuyBatcher {
    function matchAskWithTakerBidUsingAVAXAndWAVAX(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external;

    function matchBidWithTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    ) external;
}