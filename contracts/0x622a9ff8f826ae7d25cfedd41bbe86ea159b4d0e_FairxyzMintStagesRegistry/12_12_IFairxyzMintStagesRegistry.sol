// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

struct Stage {
    uint40 startTime;
    uint40 endTime;
    uint40 mintsPerWallet;
    uint40 phaseLimit;
    uint96 price;
}

interface IFairxyzMintStagesRegistry {
    error NoActiveStage();
    error NoStages();
    error NoStagesSpecified();
    error PhaseLimitsOverlap();
    error SkippedStages();
    error StageDoesNotExist();
    error StageHasEnded();
    error StageHasAlreadyStarted();
    error StageLimitAboveMax();
    error StageLimitBelowMin();
    error StageTimesOverlap();
    error TooManyUpcomingStages();
    error Unauthorized();

    /// @dev Emitted when a range of stages for a schedule are updated.
    event ScheduleStagesUpdated(
        address indexed registrant,
        uint256 indexed scheduleId,
        uint256 startIndex,
        Stage[] stages
    );

    /// @dev Emitted when a range of stages for a schedule are cancelled.
    event ScheduleStagesCancelled(
        address indexed registrant,
        uint256 indexed scheduleId,
        uint256 startIndex
    );

    /**
     * @dev Cancels all stages from the specified index onwards.
     *
     * Requirements:
     * - `fromIndex` must be less than the total number of stages
     *
     * @param registrant the address of the registrant the schedule is managed by
     * @param scheduleId the id of the schedule to cancel the stages for
     * @param fromIndex the index from which to cancel stages
     */
    function cancelStages(
        address registrant,
        uint256 scheduleId,
        uint256 fromIndex
    ) external;

    /**
     * @dev Sets a new series of stages, overwriting any existing stages and cancelling any stages after the last new stage.
     *
     * @param registrant the address of the registrant the schedule is managed by
     * @param scheduleId the id of the schedule to update the stages for
     * @param firstStageIndex the index from which to update stages
     * @param stages array of new stages to add to / overwrite existing stages
     * @param minPhaseLimit the minimum phaseLimit for the new stages e.g. current supply of the token the schedule is for
     * @param maxPhaseLimit the maximum phaseLimit for the new stages e.g. maximum supply of the token the schedule is for
     */
    function setStages(
        address registrant,
        uint256 scheduleId,
        uint256 firstStageIndex,
        Stage[] calldata stages,
        uint256 minPhaseLimit,
        uint256 maxPhaseLimit
    ) external;

    /**
     * @dev Finds the active stage for a schedule based on the current time being between the start and end times.
     * @dev Reverts if no active stage is found.
     *
     * @param scheduleId The id of the schedule to find the active stage for
     *
     * @return index The index of the active stage
     * @return stage The active stage data
     */
    function viewActiveStage(
        address registrant,
        uint256 scheduleId
    ) external view returns (uint256 index, Stage memory stage);

    /**
     * @dev Finds the final stage for a schedule.
     * @dev Does not revert. Instead, it returns an empty Stage if no stages exist for the schedule.
     *
     * @param scheduleId The id of the schedule to find the final stage for
     *
     * @return index The index of the final stage
     * @return stage The final stage data
     */
    function viewFinalStage(
        address registrant,
        uint256 scheduleId
    ) external view returns (uint256 index, Stage memory stage);

    /**
     * @dev Finds the index of the current/upcoming stage which has not yet ended.
     * @dev A stage may not exist at the returned index if all existing stages have ended.
     *
     * @param scheduleId The id of the schedule to find the latest stage index for
     *
     * @return index
     */
    function viewLatestStageIndex(
        address registrant,
        uint256 scheduleId
    ) external view returns (uint256 index);

    /**
     * @dev Returns the stage data for the specified schedule id and stage index.
     * @dev Reverts if a stage does not exist or has been deleted at the index.
     *
     * @param scheduleId The id of the schedule to get the stage from
     * @param stageIndex The index of the stage to get
     *
     * @return stage
     */
    function viewStage(
        address registrant,
        uint256 scheduleId,
        uint256 stageIndex
    ) external view returns (Stage memory stage);
}