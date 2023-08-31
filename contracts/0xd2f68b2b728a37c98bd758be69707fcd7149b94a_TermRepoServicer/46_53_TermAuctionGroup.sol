//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "../interfaces/ITermAuctionBidLocker.sol";
import "../interfaces/ITermAuctionOfferLocker.sol";
import "../TermAuction.sol";

/// @dev TermMaturityPeriod represents the contracts in a maturity period. This does not inlude auctions
struct TermAuctionGroup {
    /// @dev The address of the term auction contract
    TermAuction auction;
    /// @dev The address of the collateral manager
    ITermAuctionBidLocker termAuctionBidLocker;
    /// @dev The address of the term repo locker
    ITermAuctionOfferLocker termAuctionOfferLocker;
}