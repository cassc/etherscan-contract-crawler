//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @dev TermAuctionOffer represents an offer to offeror an amount of money for a specific interest rate
struct TermAuctionOffer {
    /// @dev Unique identifier for this bid
    bytes32 id;
    /// @dev The address of the offeror
    address offeror;
    /// @dev Hash of the offered price as a percentage of the initial loaned amount vs amount returned at maturity. This stores 9 decimal places
    bytes32 offerPriceHash;
    /// @dev Revealed offer price. This is not valid unless isRevealed is true. This stores 18 decimal places
    uint256 offerPriceRevealed;
    /// @dev The maximum amount of purchase tokens that can be lent
    uint256 amount;
    /// @dev The address of the ERC20 purchase token
    address purchaseToken;
    /// @dev Is offer price revealed
    bool isRevealed;
}