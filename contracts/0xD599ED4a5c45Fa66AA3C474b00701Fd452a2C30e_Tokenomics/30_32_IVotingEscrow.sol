// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Interface for voting escrow.
interface IVotingEscrow {
    /// @dev Gets the voting power.
    /// @param account Account address.
    function getVotes(address account) external view returns (uint256);
}