// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for Kapital DAO Governance
 * @author Playground Labs
 * @custom:security-contact [email protected]
 */
interface IGovernance {
    function votingPeriod() external view returns (uint256); // used when reporting voting weight to prevent double-voting

    struct Proposal {
        bytes32 paramsHash; // hash of proposal data
        uint56 time; // proposal timestamp
        uint96 yays; // votes for proposal
        uint96 nays; // votes against proposal
        bool executed; // to make sure a proposal is only executed once
        bool vetoed; // vetoed proposal cannot be executed or voted on 
    }

    event Propose(
        address indexed proposer,
        uint256 indexed proposalId,
        address[] targets,
        uint256[] values,
        bytes[] data
    );
    event Vote(
        address indexed voter,
        uint256 indexed proposalId,
        bool yay,
        uint256 votingWeight
    );
    event Execute(address indexed executor, uint256 indexed proposalId);
    event Veto(uint256 indexed proposalId);
}