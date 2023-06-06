// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @dev Common loan offer struct to be used both the borrower and lender
///      to propose new offers,
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId NFT collateral token id
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanOffer {
    address nftCollateralContract;
    uint256 nftCollateralId;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Collection loan offer struct to be used to making collection
///      specific offers and trait level offers.
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralIdRoot Merkle root of the tokenIds for collateral
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
struct CollectionLoanOffer {
    address nftCollateralContract;
    bytes32 nftCollateralIdRoot;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}

/// @dev Update loan offer struct to propose new terms for an ongoing loan.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanUpdateOffer {
    uint256 loanId;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    address owner;
    uint256 nonce;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Main loan struct that stores the details of an ongoing loan.
///      This struct is used to create hashes and store them in promissory tokens.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId TokenId of the NFT collateral
/// @param loanPaymentToken Address of the ERC20 token involved
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanStartTime Timestamp of when the loan started
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest Rate of the loan
/// @param isLoanProrated Flag for interest rate type of loan
struct Loan {
    uint256 loanId;
    address nftCollateralContract;
    uint256 nftCollateralId;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanStartTime;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}