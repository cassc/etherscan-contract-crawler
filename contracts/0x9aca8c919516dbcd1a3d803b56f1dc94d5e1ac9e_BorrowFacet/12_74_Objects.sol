// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice file for type definitions not used in storage

/// @notice 27-decimals fixed point unsigned number
type Ray is uint256;

/// @notice Arguments to buy the collateral of one loan
/// @param loanId loan identifier
/// @param to address that will receive the collateral
/// @param maxPrice maximum price to pay for the collateral
struct BuyArg {
    uint256 loanId;
    address to;
    uint256 maxPrice;
}

/// @notice Arguments to borrow from one collateral
/// @param nft asset to use as collateral
/// @param args arguments for the borrow parameters of the offers to use with the collateral
struct BorrowArg {
    NFToken nft;
    OfferArg[] args;
}

/// @notice Arguments for the borrow parameters of an offer
/// @dev '-' means n^th
/// @param apiCoSignedPayload api validation info and lender signature
/// @param apiSignature - of the api co-signed payload
/// @param amount - to borrow from this offer
/// @param merkleProof - that the NFT intended to be used as collateral is in the list of accepted NFTs
/// @param offer intended for usage in the loan
struct OfferArg {
    ApiCoSignedPayload apiCoSignedPayload;
    bytes apiSignature;
    uint256 amount;
    bytes32[] merkleProof;
    Offer offer;
}

/// @notice EIP-712 payload signed by the API to confirm validity of a lender signed offer
/// @param inclusionLimitDate date after which the signature is invalid
/// @param lenderSignature the EIP-712 lender signed digest of the Offer object agreed upon
struct ApiCoSignedPayload {
    uint256 inclusionLimitDate;
    bytes lenderSignature;
}

/// @notice Data on collateral state during the matching process of a NFT
///     with multiple offers
/// @param matched proportion from 0 to 1 of the collateral value matched by offers
/// @param assetLent - ERC20 that the protocol will send as loan
/// @param tranche identifier of the interest rate tranche that will be used for the loan
/// @param minOfferDuration minimal duration among offers used
/// @param minOfferLoanToValue
/// @param maxOfferLoanToValue
/// @param from original owner of the nft (borrower in most cases)
/// @param nft the collateral asset
/// @param loanId loan identifier
struct CollateralState {
    Ray matched;
    IERC20 assetLent;
    uint256 tranche;
    uint256 minOfferDuration;
    uint256 minOfferLoanToValue;
    uint256 maxOfferLoanToValue;
    address from;
    NFToken nft;
    uint256 loanId;
}

/// @notice Loan offer
/// @param assetToLend address of the ERC-20 to lend
/// @param loanToValue amount to lend per collateral
/// @param duration in seconds, time before mandatory repayment after loan start
/// @param expirationDate date after which the offer can't be used
/// @param tranche identifier of the interest rate tranche
/// @param nftListMerkleRoot merkle root of the list of NFTs accepted as collateral
struct Offer {
    IERC20 assetToLend;
    uint256 loanToValue;
    uint256 duration;
    uint256 expirationDate;
    uint256 tranche;
    bytes32 nftListMerkleRoot;
}

/// @title Non Fungible Token
/// @notice describes an ERC721 compliant token, can be used as single spec
///     I.e Collateral type accepting one specific NFT
/// @dev found in storgae
/// @param implem address of the NFT contract
/// @param id token identifier
struct NFToken {
    IERC721 implem;
    uint256 id;
}