// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/solmate/src/tokens/ERC721.sol";

import { Input, Fee } from "../../exchangeV1/lib/OrderStructs.sol";
import { Order as OrderV2, Listing } from "../../exchangeV2/lib/Structs.sol";

struct LienPointer {
    Lien lien;
    uint256 lienId;
}

struct SellOffer {
    address borrower;
    uint256 lienId;
    uint256 price;
    uint256 expirationTime;
    uint256 salt;
    address oracle;
    Fee[] fees;
}

struct Lien {
    address lender;
    address borrower;
    ERC721 collection;
    uint256 tokenId;
    uint256 amount;
    uint256 startTime;
    uint256 rate;
    uint256 auctionStartBlock;
    uint256 auctionDuration;
}

struct LoanOffer {
    address lender;
    ERC721 collection;
    uint256 totalAmount;
    uint256 minAmount;
    uint256 maxAmount;
    uint256 auctionDuration;
    uint256 salt;
    uint256 expirationTime;
    uint256 rate;
    address oracle;
}

struct LoanInput {
    LoanOffer offer;
    bytes signature;
}

struct SellInput {
    SellOffer offer;
    bytes signature;
}

struct ExecutionV1 {
    Input makerOrder;
    bytes extraSignature;
    uint256 blockNumber;
}

struct BidExecutionV2 {
    OrderV2 order;
    Listing listing;
    bytes32[] proof;
    bytes signature;
    bytes oracleSignature;
}

struct AskExecutionV2 {
    OrderV2 order;
    Listing listing;
    bytes32[] proof;
    bytes signature;
    bytes oracleSignature;
}