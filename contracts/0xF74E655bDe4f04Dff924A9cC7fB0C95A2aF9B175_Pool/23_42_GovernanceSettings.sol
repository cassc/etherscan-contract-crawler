// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../interfaces/registry/IRegistry.sol";
import "../interfaces/registry/IRecordsRegistry.sol";
import "../interfaces/governor/IGovernanceSettings.sol";
import "../libraries/ExceptionsLibrary.sol";

abstract contract GovernanceSettings is IGovernanceSettings {
    // CONSTANTS

    /// @notice Denominator for shares (such as thresholds)
    uint256 private constant DENOM = 100 * 10**4;

    // STORAGE

    /// @notice The minimum amount of votes required to create a proposal
    uint256 public proposalThreshold;

    /// @notice The minimum amount of votes which need to participate in the proposal in order for the proposal to be considered valid, given as a percentage of all existing votes
    uint256 public quorumThreshold;

    /// @notice The minimum amount of votes which are needed to approve the proposal, given as a percentage of all participating votes
    uint256 public decisionThreshold;

    /// @notice The amount of time for which the proposal will remain active, given as the number of blocks which have elapsed since the creation of the proposal
    uint256 public votingDuration;

    /// @notice The threshold value for a transaction which triggers the transaction execution delay
    uint256 public transferValueForDelay;

    /// @notice Returns transaction execution delay values for different proposal types
    mapping(IRegistry.EventType => uint256) public executionDelays;

    /// @notice Delay before voting starts. In blocks
    uint256 public votingStartDelay;

    /// @notice Storage gap (for future upgrades)
    uint256[49] private __gap;

    // EVENTS

    /// @notice This event emitted only when the following values (governance settings) are set
    event GovernanceSettingsSet(
        uint256 proposalThreshold_,
        uint256 quorumThreshold_,
        uint256 decisionThreshold_,
        uint256 votingDuration_,
        uint256 transferValueForDelay_,
        uint256[4] executionDelays_,
        uint256 votingStartDelay_
    );

    // PUBLIC FUNCTIONS

    /**
     * @notice Updates governance settings
     * @param settings New governance settings
     */
    function setGovernanceSettings(NewGovernanceSettings memory settings)
        external
    {
        // The governance settings function can only be called by the pool contract
        require(msg.sender == address(this), ExceptionsLibrary.INVALID_USER);

        // Internal function to update governance settings
        _setGovernanceSettings(settings);
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Updates governance settings
     * @param settings New governance settings
     */
    function _setGovernanceSettings(NewGovernanceSettings memory settings)
        internal
    {
        // Validates the values for governance settings
        _validateGovernanceSettings(settings);

        // Apply settings
        proposalThreshold = settings.proposalThreshold;
        quorumThreshold = settings.quorumThreshold;
        decisionThreshold = settings.decisionThreshold;
        votingDuration = settings.votingDuration;
        transferValueForDelay = settings.transferValueForDelay;

        executionDelays[IRecordsRegistry.EventType.None] = settings
            .executionDelays[0];
        executionDelays[IRecordsRegistry.EventType.Transfer] = settings
            .executionDelays[1];
        executionDelays[IRecordsRegistry.EventType.TGE] = settings
            .executionDelays[2];
        executionDelays[
            IRecordsRegistry.EventType.GovernanceSettings
        ] = settings.executionDelays[3];

        votingStartDelay = settings.votingStartDelay;
    }

    // INTERNAL VIEW FUNCTIONS

    /**
     * @notice Validates governance settings
     * @param settings New governance settings
     */
    function _validateGovernanceSettings(NewGovernanceSettings memory settings)
        internal
        pure
    {
        // Check all values for sanity
        require(
            settings.quorumThreshold < DENOM,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(
            settings.decisionThreshold <= DENOM,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(settings.votingDuration > 0, ExceptionsLibrary.INVALID_VALUE);
    }
}