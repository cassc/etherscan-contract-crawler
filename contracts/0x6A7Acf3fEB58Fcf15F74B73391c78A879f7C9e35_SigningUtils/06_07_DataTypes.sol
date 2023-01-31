// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

/**
 * @title  Loan data types
 * @author XY3
 */

/**
 * @dev Signature data for both lender & broker.
 * @param signer - The address of the signer.
 * @param nonce User offer nonce.
 * @param expiry  The signature expires date.
 * @param signature  The ECDSA signature, singed off-chain.
 */
struct Signature {
    uint256 nonce;
    uint256 expiry;
    address signer;
    bytes signature;
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
    uint256 borrowAmount;
    uint256 repayAmount;
    uint256 nftTokenId;
    address borrowAsset;
    uint32 loanDuration;
    uint16 adminShare;
    uint64 loanStart;
    address nftAsset;
    bool isCollection;
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
    uint256 borrowAmount;
    uint256 repayAmount;
    address nftAsset;
    uint32 borrowDuration;
    address borrowAsset;
    uint256 timestamp;
    bytes extra;
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
}