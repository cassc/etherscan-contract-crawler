// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {MakerOrder, TakerOrder, ERC721NFT, ERC1155NFT} from "../libraries/OrderStructs.sol";

interface ITreasureLandExchange {

    function matchAskWithTakerBid(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable;

    function matchBidWithTakerAsk(
        TakerOrder calldata takerAsk,
        MakerOrder calldata makerBid
    ) external;

    function batchMatchAskWithTakerBid(
        MakerOrder[] calldata makerAsks,
        TakerOrder calldata takerAsk
    ) external payable returns (bool[] memory successList);

    function batchMatchBidWithTakerAsk(
        MakerOrder[] calldata makerBids,
        TakerOrder calldata takerBid
    ) external returns (bool[] memory successList);

    function cancelOrder(uint256 orderNonce) external;

    function batchCancelOrders(uint256[] calldata orderNonces) external;
}