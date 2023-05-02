// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGovernanceSettings {
    /**
     * @notice Governance settings
     * @param proposalThreshold_ Proposal threshold
     * @param quorumThreshold_ Quorum threshold
     * @param decisionThreshold_ Decision threshold
     * @param votingDuration_ Voting duration
     * @param transferValueForDelay_ Transfer value for delay
     * @param executionDelays_ List of execution delays for all proposal types
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