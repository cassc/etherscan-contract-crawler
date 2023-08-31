//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @dev TermAuctionBid represents an offer to offeror an amount of money for a specific interest rate
struct TermAuctionRevealedOffer {
    /// @dev Unique identifier for this bid
    bytes32 id;
    /// @dev The address of the offeror
    address offeror;
    /// @dev The offered price as a percentage of the initial loaned amount vs amount returned at maturity. This stores 9 decimal places
    uint256 offerPriceRevealed;
    /// @dev The maximum amount of purchase tokens offered
    uint256 amount;
    /// @dev The address of the lent ERC20 token
    address purchaseToken;
}