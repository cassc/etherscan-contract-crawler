// SPDX-License-Identifier: GPL-3.0

import "../libraries/Shared.sol";

pragma solidity ^0.8.0;

interface IMarket {
    event OfferAccepted(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        Shared.Offer offer
    );

    event Bought(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        Shared.Offer offer
    );

    function acceptOffer(address seller, Shared.Offer memory offer) external;

    function buy(address buyer, Shared.Offer memory offer) external;

    function bulkPriceSet(
        uint256[] calldata tokenIds,
        address[] calldata erc20Addresses,
        uint256[] calldata amounts
    ) external;

    function removePrice(uint256 tokenId) external;

    function buyOnChain(uint256 tokenId) external;

    event BulkPriceSet(uint256[] tokenIds);

    event RemovePrice(uint256 tokenId);

    function currencies(address _currency) external view returns (bool);
}