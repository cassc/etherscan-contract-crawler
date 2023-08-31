// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error ValueNotMet(uint256 value, uint256 compareTo);
error ValuesNotEqauls(uint256 value, uint256 compareTo);
error ValueMustBeAboveZero(uint256 value);
error ValueMustBeAboveMinimumAmount(uint256 value);
error ValueMustBeMultipleOfMinimumAmount(uint256 value);

// Buy now errors
error NFTMarketBuyNow__MarketplaceNotApproved();
error NFTMarketBuyNow__SellingAgreement__AlreadyExists();
error NFTMarketBuyNow__SellingAgreement__NotTokenOwner();
error NFTMarketBuyNow__SellingAgreement__DoesNotExist();
error NFTMarketBuyNow__SellingAgreement__NotStarted();

error NFTMarketBuyNow__SellingAgreement__SellerMismatch();

// Auctions Errors
error NFTMarketAuction__AlreadyExists(uint256 auctionId);
error NFTMarketAuction__Inexistent();
error NFTMarketAuction__DoesNotHaveBids();
error NFTMarketAuction__DoesHaveBids();
error NFTMarketAuction__InvalidCaller();
error NFTMarketAuction__PriceNotMet();
error NFTMarketAuction__Ongoing();
error NFTMarketAuction__Ended();
error NFTMarketAuction__callerMustNotBeSeller();
error NFTMarketAuction__callerIsHighestBidder();
error NFTMarketAuction__ValueMustBeAboveZero(uint256 value);
error NFTMarketAuction__IsNotConfigurable();

error NFTMarketOffers__AlreadyExists(uint256 auctionId);
error NFTMarketOffers__DoesNotExist();
error NFTMarketOffers__CallerIsNotInitializer();

error EscrowWithdrawError__NoFundsToWithdraw(address wallet);