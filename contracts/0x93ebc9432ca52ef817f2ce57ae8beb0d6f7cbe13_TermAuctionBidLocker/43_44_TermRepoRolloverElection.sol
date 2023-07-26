//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/// @dev TermRepoRolloverElection represents an election to rollover a borrow into a future term
struct TermRepoRolloverElection {
    /// @dev The address of the term auction bidlocker that loan is being rolled into
    address rolloverAuction;
    /// @dev The amount of loan being rolled over
    uint256 rolloverAmount;
    /// @dev The hashed value of the rollover bid price to place in the rollover auction
    bytes32 rolloverBidPriceHash;
    /// @dev A boolean that is true if rollover is successfully locked into auction
    bool locked;
    /// @dev A boolean testing whether rollover has been successfully processsed: false if bid fails to lock or is not successful in rollover auction
    bool processed;
}