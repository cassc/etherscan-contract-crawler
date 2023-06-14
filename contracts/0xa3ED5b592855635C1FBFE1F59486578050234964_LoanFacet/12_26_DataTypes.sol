// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

/**
 * @title  Loan data types
 * @author XY3
 */

/**
 * @dev Signature data for both lender & broker.
 * @param signer - The address of the signer.
 * @param signature  The ECDSA signature, singed off-chain.
 */
struct Signature {
    address signer;
    bytes signature;
}

struct BrokerSignature {
    address signer;
    bytes signature;
    uint32 expiry;
}

enum StatusType {
    NOT_EXISTS,
    NEW,
    RESOLVED
}

/**
 * @dev Saved the loan related data.
 *
 * @param borrowAmount - The original amount of money transferred from lender to borrower.
 * @param repayAmount - The maximum amount of money that the borrower would be required to retrieve their collateral.
 * @param nftTokenId - The ID within the Xy3 NFT.
 * @param borrowAsset - The ERC20 currency address.
 * @param loanDuration - The alive time of loan in seconds.
 * @param adminShare - The admin fee percent from paid loan.
 * @param loanStart - The block.timestamp the loan start in seconds.
 * @param nftAsset - The address of the the Xy3 NFT contract.
 * @param isCollection - The accepted offer is a collection or not.
 */
struct LoanDetail {
    StatusType state;
    uint64 reserved;
    uint32 loanDuration;
    uint16 adminShare;
    uint64 loanStart;
    uint8 borrowAssetIndex;
    uint32 nftAssetIndex;
    uint112 borrowAmount;
    uint112 repayAmount;
    uint256 nftTokenId;
}

enum ItemType {
    ERC721,
    ERC1155
}
/**
 * @dev The offer made by the lender. Used as parameter on borrow.
 *
 * @param borrowAsset - The address of the ERC20 currency.
 * @param borrowAmount - The original amount of money transferred from lender to borrower.
 * @param repayAmount - The maximum amount of money that the borrower would be required to retrieve their collateral.
 * @param nftAsset - The address of the the Xy3 NFT contract.
 * @param borrowDuration - The alive time of borrow in seconds.
 * @param timestamp - For timestamp cancel
 * @param extra - Extra bytes for only signed check
 */
struct Offer {
    ItemType itemType;
    uint256 borrowAmount;
    uint256 repayAmount;
    address nftAsset;
    address borrowAsset;
    uint256 tokenId;
    uint32 borrowDuration;
    uint32 validUntil;
    uint32 amount;
    Signature signature;
}

/**
 * @dev The data for borrow external call.
 *
 * @param target - The target contract address.
 * @param selector - The target called function.
 * @param data - The target function call data with parameters only.
 * @param referral - The referral code for borrower.
 *
 */
struct CallData {
    address target;
    bytes4 selector;
    bytes data;
    uint256 referral;
    address onBehalf;
    bytes32[] proof;
}

struct BatchBorrowParam {
    Offer offer;
    uint256 id;
    BrokerSignature brokerSignature;
    CallData extraData;
}

uint16 constant HUNDRED_PERCENT = 10000;
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
uint256 constant NFT_COLLECTION_ID = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;