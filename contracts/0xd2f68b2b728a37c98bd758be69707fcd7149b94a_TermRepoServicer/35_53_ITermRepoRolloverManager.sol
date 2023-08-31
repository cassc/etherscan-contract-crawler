//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "../lib/TermRepoRolloverElection.sol";
import "../lib/TermRepoRolloverElectionSubmission.sol";

interface ITermRepoRolloverManager {
    // ========================================================================
    // = APIs  ================================================================
    // ========================================================================

    /// @notice An external function that accepted Term Repo rollover instructions
    /// @param termRepoRolloverElectionSubmission A struct containing borrower rollover instructions
    function electRollover(
        TermRepoRolloverElectionSubmission
            calldata termRepoRolloverElectionSubmission
    ) external;

    /// @notice A view function that returns borrower rollover instructions
    /// @param borrower The address of the borrower
    /// @return A struct containing borrower rollover instructions
    function getRolloverInstructions(
        address borrower
    ) external view returns (TermRepoRolloverElection memory);

    /// @notice An external function to cancel previously submitted rollover instructions, if it hasn't been locked into an auction
    function cancelRollover() external;

    /// @notice An external function that submits rollover bids given a list of borrower addresses
    /// @param borrowersToRollover An array containing borrower addresses to process for rollover
    function batchProcessRollovers(
        address[] calldata borrowersToRollover
    ) external;

    // ========================================================================
    // = Fulfiller Functions ================================================
    // ========================================================================

    /// @notice An external function called by repo servicer to to mark rollover as fulfilled
    /// @param borrower The address of the borrower
    function fulfillRollover(address borrower) external;
}