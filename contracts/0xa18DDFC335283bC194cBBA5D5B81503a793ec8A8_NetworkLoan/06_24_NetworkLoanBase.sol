// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma abicoder v2;

import "../library/NetworkLoanData.sol";
import "../interfaces/INetworkLoan.sol";

abstract contract NetworkLoanBase is INetworkLoan {
    ///@dev Load library structs into contract
    using NetworkLoanData for *;

    ///@dev saves information in loanOffers when createLoan function is called
    mapping(uint256 => NetworkLoanData.LoanDetails) public borrowerOffers;

    ///@dev mapping saves the information of the lender across the active loanId
    mapping(uint256 => NetworkLoanData.LenderDetails)
        public activatedLoanByLenders;

    //array of all loan offer ids of the ERC20 tokens.
    uint256[] public loanOfferIds;

    ///@dev users loan offers Ids
    mapping(address => uint256[]) public borrowerloanOfferIds;

    ///@dev mapping address of lender to the loan Ids
    mapping(address => uint256[]) public lenderActivatedLoanIds;

    /// @dev mapping for storing the plaform Fee and unearned APY Fee at the time of payback or liquidation
    /// @dev add the value in the mapping like that:
    // [networkMarket][stableCoinAddress] += platformFee OR Unearned APY Fee
    mapping(address => mapping(address => uint256))
        public stableCoinWithdrawable;

    /// @dev mapping to add the collateral token amount when autosell off
    /// @dev remaining tokens will be added to the collateralsWithdrawable mapping, while liquidation
    mapping(address => uint256) public collateralsWithdrawable;

    /**
    @dev function that will get APY fee of the loan amount in borrowed
     */
    function getAPYFee(NetworkLoanData.LoanDetails memory _loanDetails)
        external
        pure
        override
        returns (uint256)
    {
        /// @dev APY Fee Formula for the autoSell Fee
        return
            ((_loanDetails.loanAmountInBorrowed * _loanDetails.apyOffer) /
                10000 /
                365) * _loanDetails.termsLengthInDays;
    }

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external pure override returns (uint256) {
        /// @dev APY Fee Formula for the autoSell fee
        return ((loanAmount * autosellAPY) / 10000 / 365) * loanterminDays;
    }
}