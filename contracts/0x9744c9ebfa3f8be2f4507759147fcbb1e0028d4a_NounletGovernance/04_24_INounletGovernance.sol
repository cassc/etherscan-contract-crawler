// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule, Permission} from "./IModule.sol";
struct Proposal {
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    string description;
}

/// @dev INounletGovernance
interface INounletGovernance is IModule {
    error InsufficientVotes();
    error NotDelegate();

    event ClaimDelegate(address _vault, address _newDelegate, address _previousDelegate);
    event ProposalSubmitted(address _vault, Proposal _proposal);
    event ProposalCancelled(address _vault, uint256 _proposalId);
    event VoteCast(address _vault, uint256 _proposalId, uint8 _support);
    event VoteCastWithReason(address _vault, uint256 _proposalId, uint8 _support, string _reason);
    event NounDelegated(address _vault, address _delegatee);

    function cancel(
        address _vault,
        uint256 _proposalId,
        bytes32[] calldata _cancelProof
    ) external;

    function castVote(
        address _vault,
        uint256 _proposalId,
        uint8 _support,
        bytes32[] calldata _castVoteProof
    ) external;

    function castVoteWithReason(
        address _vault,
        uint256 _proposalId,
        uint8 _support,
        string calldata _reason,
        bytes32[] calldata _castVoteWithReasonProof
    ) external;

    function claimDelegate(address _vault, address claimer) external;

    function delegate(
        address _vault,
        address _delegatee,
        bytes32[] calldata _delegateProof
    ) external;

    function propose(
        address _vault,
        bytes32[] calldata _proposeProof,
        Proposal calldata _proposal
    ) external;
}