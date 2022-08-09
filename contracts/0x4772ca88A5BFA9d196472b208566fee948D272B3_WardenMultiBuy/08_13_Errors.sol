// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Errors {

    // Access Errors
    error CallerNotAllowed();
    error CallerNotManager();

    // Common Errors
    error ZeroAddress();
    error NullValue();
    error InvalidValue();

    // Update Errors
    error FailRewardUpdate();

    // Offers Errors
    error AlreadyRegistered();
    error WardenNotOperator();
    error NotRegistered();
    error NotOfferOwner();

    // Registration Errors
    error NullPrice();
    error NullMaxDuration();
    error IncorrectExpiry();
    error MaxPercTooHigh();
    error MinPercOverMaxPerc();
    error MinPercTooLow();

    // Purchase Errors
    error PercentUnderMinRequired();
    error PercentOverMax();
    error DurationOverOfferMaxDuration();
    error OfferExpired();
    error DurationTooShort();
    error PercentOutOfferBonds();
    error LockEndTooShort();
    error CannotDelegate();
    error NullFees();
    error FeesTooLow();
    error FailDelegationBoost();

    // Cancel Errors
    error CannotCancelBoost();

    // Claim Fees Errors
    error NullClaimAmount();
    error AmountTooHigh();
    error ClaimBlocked();
    error ClaimNotBlocked();
    error InsufficientCash();

    // Rewards Errors
    error InvalidBoostId();
    error RewardsNotStarted();
    error RewardsAlreadyStarted();
    error BoostRewardsNull();
    error RewardsNotUpdated();
    error NotBoostBuyer();
    error AlreadyClaimed();
    error CannotClaim();
    error InsufficientRewardCash();

    // Admin Errors
    error CannotWithdrawFeeToken();
    error ReserveTooLow();
    error BaseDropTooLow();
    error MinDropTooHigh();

    // MultiBuy Errors
    error NotEnoughFees();
    error FailBoostPurchase();
    error CannotMatchOrder();
    error EmptyArray();
    error InvalidBoostOffer();

}