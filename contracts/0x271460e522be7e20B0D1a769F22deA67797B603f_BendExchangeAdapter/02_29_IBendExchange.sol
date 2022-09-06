// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IBendExchange {
    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address maker; // maker of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g. StandardSaleForFixedPrice)
        address currency;
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection
        bytes params; // additional parameters
        address interceptor;
        bytes interceptorExtra;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId; // id of the token
        uint256 minPercentageToAsk; // // slippage protection
        bytes params; // other params (e.g., tokenId)
        address interceptor;
        bytes interceptorExtra;
    }

    function matchAskWithTakerBidUsingETHAndWETH(TakerOrder calldata takerBid, MakerOrder calldata makerAsk)
        external
        payable;

    function authorizationManager() external view returns (address);
}