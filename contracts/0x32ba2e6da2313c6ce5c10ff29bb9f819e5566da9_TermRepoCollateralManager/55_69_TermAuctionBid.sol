//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @dev TermAuctionBid represents a bid to borrow a specific amount of tokens at a specific interest rate (or better)
struct TermAuctionBid {
    /// @dev Unique identifier for this bid
    bytes32 id;
    /// @dev The address of the bidder
    address bidder;
    /// @dev Hash of the offered price as a percentage of the initial loaned amount vs amount returned at maturity. This stores 9 decimal places
    bytes32 bidPriceHash;
    /// @dev Revealed bid price; this is only a valid value if isRevealed is true; this stores 18 decimal places
    uint256 bidPriceRevealed;
    /// @dev The maximum amount of purchase tokens that can be borrowed
    uint256 amount;
    /// @dev The amount of collateral tokens initially locked
    uint256[] collateralAmounts;
    /// @dev The address of the ERC20 purchase token
    address purchaseToken;
    /// @dev The addresses of the collateral ERC20 tokens in the bid
    address[] collateralTokens;
    /// @dev A boolean indicating if bid was submitted as rollover from previous term
    bool isRollover;
    /// @dev The address of term repo servicer whose bid is being rolled over
    address rolloverPairOffTermRepoServicer;
    /// @dev A boolean that is true if bid has been revealed
    bool isRevealed;
}