//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/// @dev TermRepoRolloverElectionSubmission represents a user submission for a rollover election to a future term
struct TermRepoRolloverElectionSubmission {
    /// @dev The address of the term auction bidlocker that loan is being rolled into
    address rolloverAuction;
    /// @dev The amount of loan being rolled over
    uint256 rolloverAmount;
    ///@dev The hashed value of the rollover bid price to place in the rollover auction
    bytes32 rolloverBidPriceHash;
}