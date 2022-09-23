// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for NounletProposal contract
interface INounletProposal {
    function cancel(uint256 _proposalId) external;

    function castVote(uint256 _proposalId, uint8 _support) external;

    function castVoteWithReason(
        uint256 _proposalId,
        uint8 _support,
        string calldata _reason
    ) external;

    function propose(
        address[] calldata _targets,
        uint256[] calldata _values,
        string[] calldata _signatures,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external;
}