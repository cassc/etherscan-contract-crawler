/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IBatchSignedERC721OrdersCheckerFeature {

    struct BSOrderItem {
        uint256 erc20TokenAmount;
        uint256 nftId;
    }

    struct BSCollection {
        address nftAddress;
        uint256 platformFee;
        uint256 royaltyFee;
        address royaltyFeeRecipient;
        BSOrderItem[] items;
    }

    struct BSERC721Orders {
        address maker;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 startNonce;
        address paymentToken;
        address platformFeeRecipient;
        BSCollection[] basicCollections;
        BSCollection[] collections;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BSOrderItemCheckResult {
        bool isNonceValid;
        bool isERC20AmountValid;
        address ownerOfNftId;
        address approvedAccountOfNftId;
    }

    struct BSCollectionCheckResult {
        bool isApprovedForAll;
        BSOrderItemCheckResult[] items;
    }

    struct BSERC721OrdersCheckResult {
        bytes32 orderHash;
        uint256 hashNonce;
        bool validSignature;
        BSCollectionCheckResult[] basicCollections;
        BSCollectionCheckResult[] collections;
    }

    function checkBSERC721Orders(BSERC721Orders calldata order) external view returns (BSERC721OrdersCheckResult memory r);
}