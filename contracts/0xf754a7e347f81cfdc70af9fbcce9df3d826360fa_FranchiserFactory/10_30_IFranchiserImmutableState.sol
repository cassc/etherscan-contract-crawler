// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {IVotingToken} from "./IVotingToken.sol";

/// @title Interface for immutable state shared across Franchiser-related contracts.
interface IFranchiserImmutableState {
    /// @notice The `votingToken` of the contract.
    /// @return The `votingToken`.
    function votingToken() external returns (IVotingToken);
}