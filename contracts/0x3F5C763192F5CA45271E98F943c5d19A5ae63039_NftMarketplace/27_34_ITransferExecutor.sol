// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "../lib/LibSignature.sol";

abstract contract ITransferExecutor {
    enum FeeType {
        PROTOCOL_FEE,
        PROFILE_FEE,
        GK_FEE,
        OFFER_GK,
        OFFER_PROFILE
    }

    event Transfer(LibAsset.Asset asset, address indexed from, address indexed to);
    error InvalidFeeType();

    // * @param auctionType type of auction
    // * @param asset the asset being transferred
    // * @param from address where asset is being sent from
    // * @param to address receiving said asset
    // * @param decreasingPriceValue value only used for decreasing price auction
    // * @param validRoyalty true if singular NFT asset paired with only fungible token(s) trade
    // * @param optionalNftAssets only used if validRoyalty is true, should be 1 asset => NFT collection being traded
    // * @param taker address of the taker (used to determine if trade is offer [has different pricing structure])
    struct TransferParams {
        LibSignature.AuctionType auctionType;
        LibAsset.Asset asset;
        address from;
        address to;
        uint256 decreasingPriceValue;
        bool validRoyalty;
        LibAsset.Asset[] optionalNftAssets;
        address taker;
    }

    function transfer(TransferParams memory params) internal virtual;
}