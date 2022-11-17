//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernor {
    // interface
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external;
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external pure virtual returns (uint256);

    function isAgainstVote(uint256 proposalId) external view returns (bool);
    function castVote(uint256 proposalId, uint8 support) external virtual returns (uint256 balance);
}