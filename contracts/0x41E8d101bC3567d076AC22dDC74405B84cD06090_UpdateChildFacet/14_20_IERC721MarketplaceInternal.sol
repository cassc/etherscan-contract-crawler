// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721BaseInternal} from "@solidstate/contracts/token/ERC721/base/IERC721BaseInternal.sol";

interface IERC721MarketplaceInternal is IERC721BaseInternal {
    error ERC721Marketplace__NonExistentOffer();
    error ERC721Marketplace__InvalidArguments();
    error ERC721Marketplace__PaymentFailed();
    error ERC721Marketplace__InvalidValue();
    error ERC721Marketplace__InvalidPrice();

    event OfferCreated(
        uint256 indexed tokenId,
        uint256 indexed value,
        address indexed to
    );
    event OfferWithdrawn(uint256 indexed tokenId);
    event Sale(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 value
    );
}