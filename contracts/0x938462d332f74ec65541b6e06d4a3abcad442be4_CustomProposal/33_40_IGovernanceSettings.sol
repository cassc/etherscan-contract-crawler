// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGovernanceSettings {
    /**
     * @notice This structure specifies and stores the Governance settings for each individual pool.
     * @dev More information on the thresholds (proposal, quorum, decision) and creating proposals can be found in the "Other Entities" section.
     * @param proposalThreshold_ The proposal threshold (specified in token units with decimals taken into account)
     * @param quorumThreshold_ The quorum threshold (specified as a percentage)
     * @param decisionThreshold_ The decision threshold (specified as a percentage)
     * @param votingDuration_ The duration of the voting period (specified in blocks)
     * @param transferValueForDelay_ The minimum amount in USD for which a transfer from the pool wallet will be subject to a del
     * @param executionDelays_ List of execution delays specified in blocks for different types of proposals
     * @param votingStartDelay The delay before voting starts for newly created proposals, specified in blocks
     */
    struct NewGovernanceSettings {
        uint256 proposalThreshold;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 votingDuration;
        uint256 transferValueForDelay;
        uint256[4] executionDelays;
        uint256 votingStartDelay;
    }

    function setGovernanceSettings(
        NewGovernanceSettings memory settings
    ) external;
}