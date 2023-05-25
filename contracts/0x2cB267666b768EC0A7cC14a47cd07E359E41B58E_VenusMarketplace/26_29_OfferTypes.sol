// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library OfferTypes {
    // keccak256("Offer(address buyer,address collection,uint256 tokenId,uint256 price,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,bytes params)");
    bytes32 internal constant OFFER_HASH =
        0x438f0075c50060adab1fe781f02ea48f2499627a1b5c54877dc76a19e3e599e4;

    struct Offer {
        address buyer; // buyer
        address collection; // NFT collection address
        uint256 tokenId; // NFT tokenId
        uint256 price; // price in wei
        uint256 amount; // amount of NFTs
        address strategy; // execution strategy
        address currency; // currency address
        uint256 nonce; // nonce to prevent replay attacks
        uint256 startTime; // start time of the offer
        uint256 endTime; // end time of the offer
        bytes params; // additional params
        bytes signature; // signature
    }

    struct ItemSeller {
        address seller; // seller
        uint256 price; // price in wei
        uint256 tokenId; // NFT tokenId
        bytes params; // additional params
    }

    function hash(Offer memory offer) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    OFFER_HASH,
                    offer.buyer,
                    offer.collection,
                    offer.tokenId,
                    offer.price,
                    offer.amount,
                    offer.strategy,
                    offer.currency,
                    offer.nonce,
                    offer.startTime,
                    offer.endTime,
                    keccak256(offer.params)
                )
            );
    }
}