// SPDX-License-Identifier: GPL-3.0

import "../libraries/Shared.sol";

pragma solidity ^0.8.0;

struct Offer {
    uint256 tokenId;
    address tokenAddress;
    address erc20Address;
    uint256 amount;
    uint256 createdAt;
    bytes signature;
}

interface IMarket2 {
    event OfferAccepted(
        uint256 indexed tokenId,
        address indexed tokenAddress,
        address seller,
        address buyer,
        Offer offer
    );

    event Bought(
        uint256 indexed tokenId,
        address indexed tokenAddress,
        address seller,
        address buyer,
        Offer offer
    );

    function acceptOffer(address seller, Offer memory offer) external;

    function buy(address buyer, Offer memory offer) external;
}