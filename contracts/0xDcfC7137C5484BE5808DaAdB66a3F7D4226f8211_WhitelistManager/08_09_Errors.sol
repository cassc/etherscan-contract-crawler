// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.17;

library Errors {
    //FlorinStaking
    error StakeAmountMustBeGreaterThanZero();
    error EligibleSharesMustBeGreaterThanZero();
    error UnclaimedRewardsMustBeGreaterThanZero();

    //LoanVault
    error CallerMustBeDelegate();
    error CallerMustBeFundApprover();
    error LoanAmountMustBeLessOrEqualLoansOutstanding();
    error EstimatedDefaultAmountMustBeLessOrEqualLoansOutstanding();
    error RecoveredAmountMustBeLessOrEqualLoanWriteDown();
    error DefiniteDefaultAmountMustBeLessOrEqualLoanWriteDown();
    error InsufficientAllowance();
    error CallerMustBePrimaryFunder();
    error FundingAmountMustBeGreaterThanZero();
    error UnrecognizedFundingToken();
    error NoOpenFundingRequest();
    error AmountRequestedMustBeGreaterThanZero();
    error FundingRequestDoesNotExist();
    error CallerMustBeOwnerOrDelegate();
    error DelegateCanOnlyCancelOpenFundingRequests();
    error NoChainLinkFeedAvailable();
    error ZeroOrNegativeExchangeRate();
    error ChainLinkFeedHeartBeatOutOfBoundary();
    error FundingAttemptDoesNotExist();
    error FundingAttemptNotPending();
    error DepositorNotWhitelisted();
    error AprOutOfBounds();
    error FundingFeeOutOfBounds();

    //LoanVaultRegistry
    error LoanVaultNotFound();
    error TooManyLoanVaultsRegistered();

    //FlorinToken
    error MintAmountMustBeGreaterThanZero();
    error TransferAmountMustBeGreaterThanZero();
    error EffectiveRewardAmountMustBeGreaterThanZero();
}