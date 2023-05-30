// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../v1/Governance.sol";
import "../v3-relayer-registry/GovernanceStakingUpgrade.sol";

contract GovernancePatchUpgrade is GovernanceStakingUpgrade {
    mapping(uint256 => bytes32) public proposalCodehashes;

    constructor(address stakingRewardsAddress, address gasCompLogic, address userVaultAddress)
        public
        GovernanceStakingUpgrade(stakingRewardsAddress, gasCompLogic, userVaultAddress)
    { }

    /// @notice Return the version of the contract
    function version() external pure virtual override returns (string memory) {
        return "4.patch-exploit";
    }

    /**
     * @notice Execute a proposal
     * @dev This upgrade should protect against Metamorphic contracts by comparing the proposal's extcodehash with a stored one
     * @param proposalId The proposal's ID
     */
    function execute(uint256 proposalId) public payable virtual override(Governance) {
        require(msg.sender != address(this), "Governance::propose: pseudo-external function");

        Proposal storage proposal = proposals[proposalId];

        address target = proposal.target;

        bytes32 proposalCodehash;

        assembly {
            proposalCodehash := extcodehash(target)
        }

        require(
            proposalCodehash == proposalCodehashes[proposalId],
            "Governance::propose: metamorphic contracts not allowed"
        );

        super.execute(proposalId);
    }

    /**
     * @notice Internal function called from propoese
     * @dev This should store the extcodehash of the proposal contract
     * @param proposer proposer address
     * @param target smart contact address that will be executed as result of voting
     * @param description description of the proposal
     * @return proposalId new proposal id
     */
    function _propose(address proposer, address target, string memory description)
        internal
        virtual
        override(Governance)
        returns (uint256 proposalId)
    {
        // Implies all former predicates were valid
        proposalId = super._propose(proposer, target, description);

        bytes32 proposalCodehash;

        assembly {
            proposalCodehash := extcodehash(target)
        }

        proposalCodehashes[proposalId] = proposalCodehash;
    }
}