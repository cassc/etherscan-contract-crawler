// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IHashesDAO {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (uint128);

    function queue(uint128 _proposalId) external;

    function execute(uint128 _proposalId) external payable;

    function cancel(uint128 _proposalId) external;

    function castVote(
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature
    ) external;

    function castVoteBySig(
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature,
        bytes memory _signature
    ) external;

    function veto(uint128 _proposalId, bytes[] memory _signatures) external;

    function deactivateAuthorities(bytes[] memory _signatures, address[] memory _authorities) external;

    function getActions(uint128 _proposalId) external view;

    function getAuthorityStatus(address _authority) external view returns (bool);

    function getReceipt(uint128 _proposalId, address _voter) external view returns (Receipt memory);

    function getProposal(uint128 _proposalId) external view;

    function getIsQueuedTransaction(bytes32 _txHash) external view returns (bool);

    function getProposalCount() external view returns (uint128);

    function getLatestProposalId(address _proposer) external view returns (uint128);

    function state(uint128 _proposalId) external view returns (ProposalState);
}