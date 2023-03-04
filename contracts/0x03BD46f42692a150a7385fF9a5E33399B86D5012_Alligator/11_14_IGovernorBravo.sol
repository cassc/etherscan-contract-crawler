// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGovernorBravo {
    function quorumVotes() external view returns (uint256);

    function votingDelay() external view returns (uint256);

    function votingPeriod() external view returns (uint256);

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function castVote(uint256 proposalId, uint8 support) external;

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external;
}