// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library NftLoanData {
    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED
    }

    enum LoanType {
        SINGLE_NFT,
        MULTI_NFT
    }

    struct LenderDetailsNFT {
        address lender;
        uint256 activationLoanTimeStamp;
    }

    struct LoanDetailsNFT {
        //single nft or multi nft addresses
        address[] stakedCollateralNFTsAddress;
        //single nft id or multinft id
        uint256[] stakedCollateralNFTId;
        //single nft price or multi nft price //price fetch from the opensea or rarible
        uint256[] stakedNFTPrice;
        //total Loan Amount in USD
        uint256 loanAmountInBorrowed;
        //borrower given apy percentage
        uint32 apyOffer;
        //Single NFT and multiple staked NFT
        LoanType loanType;
        //current status of the loan
        LoanStatus loanStatus;
        //user choose terms length in days
        uint56 termsLengthInDays;
        //private loans will not appear on loan market
        bool isPrivate;
        //Future use flag to insure funds as they go to protocol.
        bool isInsured;
        //borrower's address
        address borrower;
        //borrower stable coin
        address borrowStableCoin;
    }
}