// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IXExchange {
    event CancelAllOrders(address indexed user, uint256 newNonce);
    event CancelMultipleOrders(bytes32[] orderItemHashes);
    event TransferManagerSelectorUpdated(address transferManagerSelector);
    event RoyaltyEngineUpdated(address royaltyEngine);
    event MarketplaceFeeEngineUpdated(address marketplaceFeeEngine);
    event StrategyManagerUpdated(address strategyManager);
    event CurrencyManagerUpdated(address currencyManager);
    event TakerAsk(
        address indexed taker,
        address indexed maker,
        address indexed strategy,
        bytes32 orderHash,
        uint256 itemIdx,
        bytes32 orderItemHash,
        OrderTypes.Fulfillment fulfillment,
        bytes32 marketplace
    );
    event TakerBid(
        address indexed taker,
        address indexed maker,
        address indexed strategy,
        bytes32 orderHash,
        uint256 itemIdx,
        bytes32 orderItemHash,
        OrderTypes.Fulfillment fulfillment,
        bytes32 marketplace
    );
    event MarketplaceFeePayment(
        bytes32 indexed marketplace,
        address currency,
        address payable[] receivers,
        uint256[] fees
    );

    function matchAskWithTakerBidUsingETH(
        OrderTypes.MakerOrder calldata makerAsk,
        OrderTypes.TakerOrder calldata takerBid
    ) external payable;

    function matchAskWithTakerBid(
        OrderTypes.MakerOrder calldata makerAsk,
        OrderTypes.TakerOrder calldata takerBid
    ) external;

    function matchBidWithTakerAsk(
        OrderTypes.MakerOrder calldata makerBid,
        OrderTypes.TakerOrder calldata takerAsk
    ) external;

    function cancelAllOrdersForSender(uint256 nonce) external;

    function cancelMultipleOrders(
        OrderTypes.MakerOrder[] calldata orders,
        uint256[][] calldata itemIdxs
    ) external;
}