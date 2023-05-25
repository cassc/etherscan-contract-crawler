// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../structs/Rules.sol";

interface IAlligator {
    // =============================================================
    //                             EVENTS
    // =============================================================

    event ProxyDeployed(address indexed owner, address proxy);
    event SubDelegation(address indexed from, address indexed to, Rules rules);
    event SubDelegations(address indexed from, address[] to, Rules[] rules);
    event VoteCast(
        address indexed proxy,
        address indexed voter,
        address[] authority,
        uint256 proposalId,
        uint8 support
    );
    event VotesCast(
        address[] proxies,
        address indexed voter,
        address[][] authorities,
        uint256 proposalId,
        uint8 support
    );
    event Signed(address indexed proxy, address[] authority, bytes32 messageHash);

    // =============================================================
    //                       WRITE FUNCTIONS
    // =============================================================

    function create(address owner, bool registerEnsName) external returns (address endpoint);

    function registerProxyDeployment(address owner) external;

    function propose(
        address[] calldata authority,
        address[] calldata targets,
        uint256[] calldata values,
        string[] calldata signatures,
        bytes[] calldata calldatas,
        string calldata description
    ) external returns (uint256 proposalId);

    function castVote(address[] calldata authority, uint256 proposalId, uint8 support) external;

    function castVoteWithReason(
        address[] calldata authority,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external;

    function castVotesWithReasonBatched(
        address[][] calldata authorities,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external;

    function castRefundableVotesWithReasonBatched(
        address[][] calldata authorities,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external;

    function castVoteBySig(
        address[] calldata authority,
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function sign(address[] calldata authority, bytes32 hash) external;

    function subDelegate(address to, Rules calldata rules, bool createProxy) external;

    function subDelegateBatched(address[] calldata targets, Rules[] calldata rules, bool createProxy) external;

    function _togglePause() external;

    // // =============================================================
    // //                         VIEW FUNCTIONS
    // // =============================================================

    function validate(
        address sender,
        address[] memory authority,
        uint256 permissions,
        uint256 proposalId,
        uint256 support
    ) external view;

    function isValidProxySignature(
        address proxy,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4 magicValue);

    function proxyAddress(address owner) external view returns (address endpoint);
}