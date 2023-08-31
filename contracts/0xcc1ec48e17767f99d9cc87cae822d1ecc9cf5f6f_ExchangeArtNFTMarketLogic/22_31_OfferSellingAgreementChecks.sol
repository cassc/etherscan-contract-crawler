// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "../mixins/shared/Errors.sol";
import "../interfaces/IOfferSellingAgreementProvider.sol";

library OfferSellingAgreementChecks {
  function mustNotExist(uint256 offerId) internal pure {
    if (offerId != 0) {
      revert NFTMarketOffers__AlreadyExists(offerId);
    }
  }

  function mustExist(Offer memory offer) internal pure {
    if (offer.offerPrice == 0) {
      revert NFTMarketOffers__DoesNotExist();
    }
  }

  function mustBeInitializerOf(
    address sender,
    Offer memory offer
  ) internal pure {
    if (sender != offer.buyer) {
      revert NFTMarketOffers__CallerIsNotInitializer();
    }
  }
}