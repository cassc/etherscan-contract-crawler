// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma abicoder v2;

import "../library/NftLoanData.sol";
import "../interfaces/INftMarket.sol";

abstract contract NftMarketBase is INftMarket {
    //Load library structs into contract
    using NftLoanData for *;
    using NftLoanData for bytes32;

    //Single NFT or Multi NFT loan offers mapping
    mapping(uint256 => NftLoanData.LoanDetailsNFT) public loanOffersNFT;

    //mapping saves the information of the lender across the active NFT Loan Ids
    mapping(uint256 => NftLoanData.LenderDetailsNFT)
        public activatedNFTLoanOffers;

    //array of all loan offer ids of the NFT tokens.
    uint256[] public loanOfferIdsNFTs;

    //mapping of borrower address to the loan Ids of the NFT.
    mapping(address => uint256[]) public borrowerloanOffersNFTs;

    //mapping address of the lender to the activated loan offers of NFT
    mapping(address => uint256[]) public lenderActivatedLoansNFTs;

    //mapping address stable to the APY Fee of stable
    mapping(address => mapping(address => uint256))
        public stableCoinWithdrawable;

    /// @dev function returns the APY fee of the loan amount in borrow stable coin
    /// @param _loanDetailsNFT loan details to get the apy fee
    function getAPYFeeNFT(NftLoanData.LoanDetailsNFT memory _loanDetailsNFT)
        external
        pure
        returns (uint256)
    {
        // APY Fee Formula
        uint256 apyFee = ((_loanDetailsNFT.loanAmountInBorrowed *
            _loanDetailsNFT.apyOffer) /
            10000 /
            365) * _loanDetailsNFT.termsLengthInDays;
        return apyFee;
    }
}