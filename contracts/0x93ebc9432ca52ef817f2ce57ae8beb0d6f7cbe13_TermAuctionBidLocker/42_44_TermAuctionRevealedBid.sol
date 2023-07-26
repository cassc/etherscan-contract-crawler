//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @dev TermAuctionBid represents a bid to borrow an amount of money for a specific interest rate
struct TermAuctionRevealedBid {
    /// @dev Unique identifier for this bid
    bytes32 id;
    /// @dev The address of the bidder
    address bidder;
    /// @dev The offered price as a percentage of the initial loaned amount vs amount returned at maturity. This stores 9 decimal places
    uint256 bidPriceRevealed;
    /// @dev The maximum amount of TermRepoTokens borrowed. This stores 18 decimal places
    uint256 amount;
    /// @dev The amount of collateral tokens initially locked
    uint256[] collateralAmounts;
    /// @dev The purchase token address
    address purchaseToken;
    /// @dev The collateral token address
    address[] collateralTokens;
    /// @dev A boolean indicating whether bid is submitted as rollover from previous term
    bool isRollover;
    /// @dev The address of term repo servicer whose bid is being rolled over
    address rolloverPairOffTermRepoServicer;
}