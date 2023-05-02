// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../interfaces/registry/IRegistry.sol";

interface IGovernor {
    /**
     * @dev Struct with proposal core data
     * @param targets Targets
     * @param values ETH values
     * @param callDatas Call datas to pass in .call() to target
     * @param quorumThreshold Quorum threshold (as percents)
     * @param decisionThreshold Decision threshold (as percents)
     * @param executionDelay Execution delay after successful voting (blocks)
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
     * @dev Struct with proposal metadata
     * @param proposalType Proposal type
     * @param description Description
     * @param metaHash Metadata hash
     */
    struct ProposalMetaData {
        IRegistry.EventType proposalType;
        string description;
        string metaHash;
    }

    function proposalState(uint256 proposalId)
        external
        view
        returns (uint256 state);
}