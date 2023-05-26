// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  __          _______ _   _  _____ _____ _________     __
 *  \ \        / /_   _| \ | |/ ____|_   _|__   __\ \   / /
 *   \ \  /\  / /  | | |  \| | |      | |    | |   \ \_/ /
 *    \ \/  \/ /   | | | . ` | |      | |    | |    \   /
 *     \  /\  /   _| |_| |\  | |____ _| |_   | |     | |
 *      \/  \/   |_____|_| \_|\_____|_____|  |_|     |_|
 *
 * @author Wincity | Antoine Duez
 * @title OrderTypes
 * @notice This library contains the order types for Wincity exchange.
 */
library OrderTypes {
    // keccak256("ItemListing(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 nonce,uint256 startTime,uint256 endTime,bytes params)")
    bytes32 internal constant ITEM_LISTING_HASH =
        0x4684b94532f3660dabc6dcc9b3da5baf1bbf888a7d4ac3905cc5d2d1f6cb9c02;

    struct ItemListing {
        bool isOrderAsk; // true --> ask / false --> bid
        address payable signer; // signer of the listing
        address collection; // collection address
        uint256 price; // price (as ETH)
        uint256 tokenId; // id of the token
        uint256 nonce; // order nonce (must be unique unless is meant to override existing listing)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct ItemPurchase {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 tokenId; // id of the token
        bytes params; // other params (e.g., tokenId)
    }

    function hash(ItemListing memory _listing) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ITEM_LISTING_HASH,
                    _listing.isOrderAsk,
                    _listing.signer,
                    _listing.collection,
                    _listing.price,
                    _listing.tokenId,
                    _listing.nonce,
                    _listing.startTime,
                    _listing.endTime,
                    keccak256(_listing.params)
                )
            );
    }
}