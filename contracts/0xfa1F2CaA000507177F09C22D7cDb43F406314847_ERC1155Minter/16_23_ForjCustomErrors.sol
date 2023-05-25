// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract ForjCustomErrors {
    error TotalSupplyGreaterThanMaxSupply();
    error TierNumberIncorrect();
    error ArrayLengthsDiffer();
    error TierLengthTooShort();
    error ClaimPeriodTooShort();
    error PartnerAlreadyExists();
    error PartnerNotFound();
    error InvalidPartnerWallet();
    error InvalidPartnerSharePct();
    error PartnerActive();
    error PartnerDeactivated();
    error InvalidProof();
    error TierPeriodHasntStarted();
    error TierPeriodHasEnded();
    error CurrentlyNotClaimPeriod();
    error MintLimitReached();
    error MaxSupplyReached();
    error AlreadyInitialized();
    error MsgSenderIsNotOwner();
    error IncorrectAddress();
    error BaseURINotSet();
    error TokenNotAcceptedAsPayment();
    error InsufficientBalance();
    error TokenIsSoulbound();
}