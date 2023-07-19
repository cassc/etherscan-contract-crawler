// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../interfaces/registry/IRecordsRegistry.sol";

interface IGovernor {
    /**
     * @notice Struct with proposal core data
     * @dev This interface specifies the Governance settings that existed in the pool at the time of proposal creation, as well as the service data (to which addresses and with what messages and amounts of ETH should be sent) of the scenario that should be executed in case of a positive voting outcome.
     * @param targets A list of addresses to be called in case of a positive voting outcome
     * @param values The amounts of wei to be sent to the addresses from targets
     * @param callDatas The 'calldata' messages to be attached to transactions
     * @param quorumThreshold The quorum, expressed as a percentage with DENOM taken into account
     * @param decisionThreshold The decision-making threshold, expressed as a percentage with DENOM taken into account
     * @param executionDelay The number of blocks that must pass since the creation of the proposal for it to be considered launched
     */
    struct ProposalCoreData {
        address[] targets;
        uint256[] values;
        bytes[] callDatas;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 executionDelay;
    }

    /**
     * @notice This interface specifies information about the subject of the voting, intended for human perception.
     * @dev Struct with proposal metadata
     * @param proposalType The digital code of the proposal type
     * @param description The public description of the proposal
     * @param metaHash The identifier of the private proposal description stored on the backend
     */
    struct ProposalMetaData {
        IRecordsRegistry.EventType proposalType;
        string description;
        string metaHash;
    }

    function proposalState(uint256 proposalId)
        external
        view
        returns (uint256 state);
}