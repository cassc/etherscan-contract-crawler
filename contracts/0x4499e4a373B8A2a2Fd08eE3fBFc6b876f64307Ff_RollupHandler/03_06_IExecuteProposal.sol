// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IExecuteProposal {
    /// @notice It is intended that proposals are executed by the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param data Consists of additional data needed for a specific deposit execution.
    function executeProposal(bytes32 resourceID, bytes calldata data) external;
}