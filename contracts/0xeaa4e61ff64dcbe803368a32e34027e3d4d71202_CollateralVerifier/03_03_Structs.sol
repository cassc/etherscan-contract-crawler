// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*//////////////////////////////////////////////////
                COLLATERAL TYPES
//////////////////////////////////////////////////*/

enum CollateralType {
    ERC721,
    ERC1155,
    ERC721_WITH_CRITERIA,
    ERC1155_WITH_CRITERIA
}

struct Collateral {
    uint8 collateralType;
    address collection;
    uint256 collateralId;
    uint256 collateralAmount;
}

/*//////////////////////////////////////////////////
                LIEN STRUCTS
//////////////////////////////////////////////////*/

struct LienPointer {
    Lien lien;
    uint256 lienId;
}

struct Lien {
    address lender;
    address borrower;
    uint8 collateralType;
    address collection;
    uint256 tokenId;
    uint256 amount;
    address currency;
    uint256 borrowAmount;
    uint256 duration;
    uint256 rate;
    uint256 startTime;
}

/*//////////////////////////////////////////////////
                LOAN OFFER STRUCTS
//////////////////////////////////////////////////*/

struct LoanOffer {
    address lender;
    address collection;
    uint8 collateralType;
    uint256 collateralIdentifier;
    uint256 collateralAmount;
    address currency;
    uint256 totalAmount;
    uint256 minAmount;
    uint256 maxAmount;
    uint256 duration;
    uint256 rate;
    uint256 salt;
    uint256 expiration;
    Fee[] fees;
}

struct LoanOfferInput {
    LoanOffer offer;
    bytes offerSignature;
}

struct LoanFullfillment {
    uint256 offerIndex;
    uint256 loanAmount;
    uint256 collateralIdentifier;
    OfferAuth auth;
    bytes authSignature;
    bytes32[] proof;
}

/*//////////////////////////////////////////////////
                BORROW OFFER STRUCTS
//////////////////////////////////////////////////*/

struct BorrowOffer {
    address borrower;
    address collection;
    uint8 collateralType;
    uint256 collateralIdentifier;
    uint256 collateralAmount;
    address currency;
    uint256 loanAmount;
    uint256 duration;
    uint256 rate;
    uint256 salt;
    uint256 expiration;
    Fee[] fees;
}

struct BorrowOfferInput {
    BorrowOffer offer;
    bytes offerSignature;
}

struct BorrowFullfillment {
    uint256 offerIndex;
    OfferAuth auth;
    bytes authSignature;
}

/*//////////////////////////////////////////////////
                REPAY STRUCTS
//////////////////////////////////////////////////*/

struct RepayFullfillment {
    Lien lien;
    uint256 lienId;
}

/*//////////////////////////////////////////////////
                REFINANCE STRUCTS
//////////////////////////////////////////////////*/

struct RefinanceFullfillment {
    Lien lien;
    uint256 lienId;
    uint256 offerIndex;
    uint256 loanAmount;
    bytes32[] proof;
    OfferAuth auth;
    bytes authSignature;
}

/*//////////////////////////////////////////////////
                FEE STRUCTS
//////////////////////////////////////////////////*/

struct Fee {
    uint16 rate;
    address recipient;
}

/*//////////////////////////////////////////////////
                AUTH STRUCTS
//////////////////////////////////////////////////*/
struct OfferAuth {
    bytes32 offerHash;
    address taker;
    uint256 expiration;
    bytes32 collateralHash;
}