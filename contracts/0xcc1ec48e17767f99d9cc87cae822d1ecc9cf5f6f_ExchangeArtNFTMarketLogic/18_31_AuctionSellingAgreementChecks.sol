// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "hardhat/console.sol";

import "../mixins/shared/Errors.sol";
import "../interfaces/IAuctionSellingAgreementProvider.sol";

library AuctionSellingAgreementChecks {
  function mustNotExist(uint256 auctionId) internal pure {
    if (auctionId != 0) {
      revert NFTMarketAuction__AlreadyExists(auctionId);
    }
  }

  function mustExist(AuctionBasicState memory auction) internal pure {
    if (auction.reservePriceOrHighestBid == 0) {
      revert NFTMarketAuction__Inexistent();
    }
  }

  function mustBeConfigurable(AuctionBasicState memory auction) internal pure {
    if (auction.isStandardAuction) {
      revert NFTMarketAuction__IsNotConfigurable();
    }
  }

  function mustHaveEnded(
    AuctionBasicState memory auction,
    uint256 currentTime
  ) internal pure {
    if (auction.end > currentTime) {
      revert NFTMarketAuction__Ongoing();
    }
  }

  function mustBeOngoing(
    AuctionBasicState memory auction,
    uint256 currentTime,
    bool isReservePriceTriggered
  ) internal pure {
    if (
      (!isReservePriceTriggered && auction.end < currentTime) ||
      (isReservePriceTriggered &&
        auction.highestBidder != address(0) &&
        auction.end < currentTime)
    ) {
      revert NFTMarketAuction__Ended();
    }
  }

  function callerMustBeSeller(
    AuctionBasicState memory auction,
    address caller
  ) internal pure {
    if (auction.seller != caller) {
      revert NFTMarketAuction__Inexistent();
    }
  }

  function callerMustNotBeSeller(
    AuctionBasicState memory auction,
    address caller
  ) internal pure {
    if (auction.seller == caller) {
      revert NFTMarketAuction__callerMustNotBeSeller();
    }
  }

  function mustHaveAtLeastOneBid(
    AuctionBasicState memory auction
  ) internal pure {
    if (auction.highestBidder == address(0)) {
      revert NFTMarketAuction__DoesNotHaveBids();
    }
  }

  function mustNotHaveBids(AuctionBasicState memory auction) internal pure {
    if (auction.highestBidder != address(0)) {
      revert NFTMarketAuction__DoesHaveBids();
    }
  }

  function mustBeGreaterThanOrEqual(
    uint256 value,
    uint256 compareTo
  ) internal pure {
    if (compareTo > value) {
      revert NFTMarketAuction__PriceNotMet();
    }
  }

  function mustBeReedemedByOwnerOrHighestBidder(
    AuctionBasicState memory auction,
    address caller
  ) internal pure {
    if (caller != auction.seller && caller != auction.highestBidder) {
      revert NFTMarketAuction__InvalidCaller();
    }
  }

  function callerCannotBeHighestBidder(
    AuctionBasicState memory auction,
    address caller
  ) internal pure {
    if (caller == auction.highestBidder) {
      revert NFTMarketAuction__callerIsHighestBidder();
    }
  }
}