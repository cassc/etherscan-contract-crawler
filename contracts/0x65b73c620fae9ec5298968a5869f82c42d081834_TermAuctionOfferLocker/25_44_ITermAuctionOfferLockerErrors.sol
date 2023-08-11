//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./ITermAuctionLockerErrors.sol";

/// @notice ITermAuctionOfferLockerErrors is an interface that defines all errors emitted by the Term Auction Offer Locker.
interface ITermAuctionOfferLockerErrors is ITermAuctionLockerErrors {
    error GeneratingExistingOffer(bytes32 offerId);
    error MaxOfferCountReached();
    error NonExistentOffer(bytes32 id);
    error NoOfferToUnlock();
    error OfferAlreadyRevealed();
    error OfferAmountTooLow(uint256 amount);
    error OfferCountIncorrect(uint256 offerCount);
    error OfferNotOwned();
    error OfferNotRevealed(bytes32 id);
    error OfferPriceModified();
    error OfferRevealed(bytes32 id);
    error RevealedOffersNotSorted();
}