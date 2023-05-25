// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library ListingTypes {
    // keccak256("Listing(address seller,address collection,uint256 tokenId,uint256 price,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,bytes params)");
    bytes32 internal constant LISTING_HASH =
        0x1b4f32c0b43bd7ad102234c10dd17f26033c20510e5a263516db37173c423d43;

    struct Listing {
        address seller; // seller
        address collection; // NFT collection address
        uint256 tokenId; // NFT tokenId
        uint256 price; // price in wei
        uint256 amount; // amount of NFTs
        address strategy; // execution strategy
        address currency; // currency address
        uint256 nonce; // nonce to prevent replay attacks
        uint256 startTime; // start time of the listing
        uint256 endTime; // end time of the listing
        bytes params; // additional params
        bytes signature; // signature
    }

    struct ItemBuyer {
        address buyer; // buyer
        uint256 price; // price in wei
        uint256 tokenId; // NFT tokenId
        bytes params; // additional params
    }

    function hash(Listing memory listing) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    LISTING_HASH,
                    listing.seller,
                    listing.collection,
                    listing.tokenId,
                    listing.price,
                    listing.amount,
                    listing.strategy,
                    listing.currency,
                    listing.nonce,
                    listing.startTime,
                    listing.endTime,
                    keccak256(listing.params)
                )
            );
    }
}