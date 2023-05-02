// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/solmate/src/tokens/ERC721.sol";
import "./ExchangeStructs.sol";

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

struct Execution {
    Input makerOrder;
    bytes extraSignature;
    uint256 blockNumber;
}