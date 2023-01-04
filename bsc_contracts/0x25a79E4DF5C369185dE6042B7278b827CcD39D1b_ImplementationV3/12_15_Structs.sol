// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


struct SaleOrder {
    uint256 onSaleQuantity;
    uint256 price;
    uint256 tokenType;
    address seller;
    bytes saleOrderId;      // internalTxId
}

struct MintRequest {
    uint256 totalCopies;
    uint256 amount;
    uint256 priceConvert;
    address buyer;
    address tokenAddress;
    bytes nftId;
    bytes saleOrderSignature;
    bytes transactionId;    // internalTxId
}

struct BuyRequest {
    uint256 tokenId;
    uint256 amount;
    uint256 royaltyFee;
    address buyer;
    address tokenAddress;
    bytes saleOrderSignature;
    bytes transactionId;    // internalTxId
}

struct RentOrder {
    uint256 tokenId;
    uint256 fee; //per day
    uint256 expirationDate;
    uint256 deadline;
    address owner;
    address tokenAddress;
    bytes transactionId;    // internalTxId
}

struct RentRequest {
    uint256 tokenId;
    uint256 expDate;
    uint256 totalPrice;
    uint256 deadline;
    address renter;
    address tokenAddress;
    bytes transactionId;    // internalTxId
}


struct StakeRequest {
    uint256 tokenId;
    address owner;
    bytes poolId;
    bytes internalTxId;
}