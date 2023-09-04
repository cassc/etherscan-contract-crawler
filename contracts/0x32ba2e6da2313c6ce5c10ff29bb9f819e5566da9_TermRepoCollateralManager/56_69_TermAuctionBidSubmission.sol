//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @dev TermAuctionBidSubmission represents a bid submission to borrow an amount of money for a specific interest rate
struct TermAuctionBidSubmission {
    /// @dev For an existing bid this is the unique onchain identifier for this bid. For a new bid this is a randomized input that will be used to generate the unique onchain identifier.
    bytes32 id;
    /// @dev The address of the bidder
    address bidder;
    /// @dev Hash of the offered price as a percentage of the initial loaned amount vs amount returned at maturity. This stores 9 decimal places
    bytes32 bidPriceHash;
    /// @dev The maximum amount of purchase tokens that can be borrowed
    uint256 amount;
    /// @dev The amount of collateral tokens initially locked
    uint256[] collateralAmounts;
    /// @dev The address of the ERC20 purchase token
    address purchaseToken;
    /// @dev The addresses of the collateral ERC20 tokens in the bid
    address[] collateralTokens;
}