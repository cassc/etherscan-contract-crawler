// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// JoepegAuctionHouse
error JoepegAuctionHouse__AuctionAlreadyExists();
error JoepegAuctionHouse__CurrencyMismatch();
error JoepegAuctionHouse__ExpectedNonNullAddress();
error JoepegAuctionHouse__ExpectedNonZeroFinalSellerAmount();
error JoepegAuctionHouse__FeesHigherThanExpected();
error JoepegAuctionHouse__InvalidDropInterval();
error JoepegAuctionHouse__InvalidDuration();
error JoepegAuctionHouse__InvalidMinPercentageToAsk();
error JoepegAuctionHouse__InvalidStartTime();
error JoepegAuctionHouse__NoAuctionExists();
error JoepegAuctionHouse__OnlyAuctionCreatorCanCancel();
error JoepegAuctionHouse__UnsupportedCurrency();

error JoepegAuctionHouse__EnglishAuctionCannotBidOnUnstartedAuction();
error JoepegAuctionHouse__EnglishAuctionCannotBidOnEndedAuction();
error JoepegAuctionHouse__EnglishAuctionCannotCancelWithExistingBid();
error JoepegAuctionHouse__EnglishAuctionCannotSettleUnstartedAuction();
error JoepegAuctionHouse__EnglishAuctionCannotSettleWithoutBid();
error JoepegAuctionHouse__EnglishAuctionCreatorCannotPlaceBid();
error JoepegAuctionHouse__EnglishAuctionInsufficientBidAmount();
error JoepegAuctionHouse__EnglishAuctionInvalidMinBidIncrementPct();
error JoepegAuctionHouse__EnglishAuctionInvalidRefreshTime();
error JoepegAuctionHouse__EnglishAuctionOnlyCreatorCanSettleBeforeEndTime();

error JoepegAuctionHouse__DutchAuctionCannotSettleUnstartedAuction();
error JoepegAuctionHouse__DutchAuctionCreatorCannotSettle();
error JoepegAuctionHouse__DutchAuctionInsufficientAmountToSettle();
error JoepegAuctionHouse__DutchAuctionInvalidStartEndPrice();

// RoyaltyFeeManager
error RoyaltyFeeManager__InvalidRoyaltyFeeRegistryV2();
error RoyaltyFeeManager__RoyaltyFeeRegistryV2AlreadyInitialized();

// RoyaltyFeeRegistryV2
error RoyaltyFeeRegistryV2__InvalidMaxNumRecipients();
error RoyaltyFeeRegistryV2__RoyaltyFeeCannotBeZero();
error RoyaltyFeeRegistryV2__RoyaltyFeeLimitTooHigh();
error RoyaltyFeeRegistryV2__RoyaltyFeeRecipientCannotBeNullAddr();
error RoyaltyFeeRegistryV2__RoyaltyFeeSetterCannotBeNullAddr();
error RoyaltyFeeRegistryV2__RoyaltyFeeTooHigh();
error RoyaltyFeeRegistryV2__TooManyFeeRecipients();

// RoyaltyFeeSetterV2
error RoyaltyFeeSetterV2__CollectionCannotSupportERC2981();
error RoyaltyFeeSetterV2__CollectionIsNotNFT();
error RoyaltyFeeSetterV2__NotCollectionAdmin();
error RoyaltyFeeSetterV2__NotCollectionOwner();
error RoyaltyFeeSetterV2__NotCollectionSetter();
error RoyaltyFeeSetterV2__SetterAlreadySet();

// PendingOwnable
error PendingOwnable__NotOwner();
error PendingOwnable__AddressZero();
error PendingOwnable__NotPendingOwner();
error PendingOwnable__PendingOwnerAlreadySet();
error PendingOwnable__NoPendingOwner();

// PendingOwnableUpgradeable
error PendingOwnableUpgradeable__NotOwner();
error PendingOwnableUpgradeable__AddressZero();
error PendingOwnableUpgradeable__NotPendingOwner();
error PendingOwnableUpgradeable__PendingOwnerAlreadySet();
error PendingOwnableUpgradeable__NoPendingOwner();

// SafeAccessControlEnumerable
error SafeAccessControlEnumerable__SenderMissingRoleAndIsNotOwner(
    bytes32 role,
    address sender
);
error SafeAccessControlEnumerable__RoleIsDefaultAdmin();

// SafeAccessControlEnumerableUpgradeable
error SafeAccessControlEnumerableUpgradeable__SenderMissingRoleAndIsNotOwner(
    bytes32 role,
    address sender
);
error SafeAccessControlEnumerableUpgradeable__RoleIsDefaultAdmin();

// SafePausable
error SafePausable__AlreadyPaused();
error SafePausable__AlreadyUnpaused();

// SafePausableUpgradeable
error SafePausableUpgradeable__AlreadyPaused();
error SafePausableUpgradeable__AlreadyUnpaused();