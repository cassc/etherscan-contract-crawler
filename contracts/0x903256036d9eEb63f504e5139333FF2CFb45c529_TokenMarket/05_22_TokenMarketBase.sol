// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
pragma abicoder v2;

import "../library/TokenLoanData.sol";
import "../interfaces/ITokenMarket.sol";

abstract contract TokenMarketBase is ITokenMarket {
    //Load library structs into contract
    using TokenLoanData for *;
    //saves the transaction hash of the create loan offer transaction as loanId
    mapping(uint256 => TokenLoanData.LoanDetails) public loanOffersToken;

    //mapping saves the information of the lender across the active loanId
    mapping(uint256 => TokenLoanData.LenderDetails) public activatedLoanOffers;

    //array of all loan offer ids of the ERC20 tokens.
    uint256[] public loanOfferIds;

    //erc20 tokens loan offer mapping
    mapping(address => uint256[]) public borrowerloanOfferIds;

    //mapping address of lender => loan Ids
    mapping(address => uint256[]) public lenderActivatedLoanIds;

}