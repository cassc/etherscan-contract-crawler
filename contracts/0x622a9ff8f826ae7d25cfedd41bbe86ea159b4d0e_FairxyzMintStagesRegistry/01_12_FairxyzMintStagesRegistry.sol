// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IFairxyzMintStagesRegistry, Stage} from "../interfaces/IFairxyzMintStagesRegistry.sol";

/**
 * @title Fair.xyz Mint Stages Registry
 * @author Fair.xyz Developers
 * @notice A registry for scheduling sequential mint stages used by NFT minting contracts.
 */
contract FairxyzMintStagesRegistry is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IFairxyzMintStagesRegistry
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 internal immutable MAX_UPCOMING_STAGES; // used to limit the number of upcoming stages to prevent gas exhaustion

    /// @dev map scheduleId to stages
    mapping(address => mapping(uint256 => mapping(uint256 => Stage)))
        internal _scheduleStages;

    /// @dev map scheduleId to stages count
    mapping(address => mapping(uint256 => uint256))
        internal _scheduleStagesCount;

    modifier onlyRegistrant(address registrant) {
        if (msg.sender != registrant) revert Unauthorized();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 maxUpcomingStages_) {
        MAX_UPCOMING_STAGES = maxUpcomingStages_;
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    // * PUBLIC * //

    /**
     * @dev See {IFairxyzMintStagesRegistry-cancelStages}.
     */
    function cancelStages(
        address registrant,
        uint256 scheduleId,
        uint256 fromIndex
    ) external virtual override onlyRegistrant(registrant) {
        uint256 currentTotalStages = _scheduleStagesCount[registrant][
            scheduleId
        ];

        if (fromIndex < currentTotalStages) {
            if (
                _scheduleStages[registrant][scheduleId][fromIndex].startTime <=
                block.timestamp
            ) {
                revert StageHasAlreadyStarted();
            }

            _scheduleStagesCount[registrant][scheduleId] = fromIndex;

            emit ScheduleStagesCancelled(registrant, scheduleId, fromIndex);
        } else {
            revert StageDoesNotExist();
        }
    }

    /**
     * @dev See {IFairxyzMintStagesRegistry-setStages}.
     */
    function setStages(
        address registrant,
        uint256 scheduleId,
        uint256 firstStageIndex,
        Stage[] calldata stages,
        uint256 minPhaseLimit,
        uint256 maxPhaseLimit
    ) external virtual override onlyRegistrant(registrant) {
        uint256 stagesCount = stages.length;
        if (stagesCount == 0) {
            revert NoStagesSpecified();
        }

        uint256 newStagesCount = firstStageIndex + stagesCount;
        if (
            newStagesCount - viewLatestStageIndex(registrant, scheduleId) >
            MAX_UPCOMING_STAGES
        ) {
            revert TooManyUpcomingStages();
        }

        Stage memory newStage = stages[0];

        // first new stage phaseLimit must be greater than or equal to the specified minimum
        if (newStage.phaseLimit > 0) {
            if (newStage.phaseLimit < minPhaseLimit)
                revert StageLimitBelowMin();
        }

        _setStage(registrant, scheduleId, firstStageIndex, newStage);

        if (stagesCount > 1) {
            // validate and store additional stages
            newStage = _setAdditionalStages(
                registrant,
                scheduleId,
                firstStageIndex,
                stages,
                stagesCount
            );
        }

        // last new stage phaseLimit must be less than or equal to the specified maximum
        if (
            maxPhaseLimit > 0 &&
            (newStage.phaseLimit == 0 || newStage.phaseLimit > maxPhaseLimit)
        ) revert StageLimitAboveMax();

        uint256 originalStagesCount = _scheduleStagesCount[registrant][
            scheduleId
        ];

        _scheduleStagesCount[registrant][scheduleId] = newStagesCount;

        emit ScheduleStagesUpdated(
            registrant,
            scheduleId,
            firstStageIndex,
            stages
        );

        if (newStagesCount < originalStagesCount) {
            emit ScheduleStagesCancelled(
                registrant,
                scheduleId,
                newStagesCount
            );
        }
    }

    /**
     * @dev See {IFairxyzMintStagesRegistry-viewActiveStage}.
     */
    function viewActiveStage(
        address registrant,
        uint256 scheduleId
    )
        external
        view
        virtual
        override
        returns (uint256 index, Stage memory stage)
    {
        for (
            index = _scheduleStagesCount[registrant][scheduleId];
            index > 0;

        ) {
            unchecked {
                --index;
            }

            stage = _scheduleStages[registrant][scheduleId][index];

            if (
                block.timestamp >= stage.startTime &&
                (stage.endTime == 0 || block.timestamp <= stage.endTime)
            ) {
                return (index, stage);
            }
        }

        revert NoActiveStage();
    }

    /**
     * @dev See {IFairxyzMintStagesRegistry-viewFinalStage}.
     */
    function viewFinalStage(
        address registrant,
        uint256 scheduleId
    )
        external
        view
        virtual
        override
        returns (uint256 index, Stage memory stage)
    {
        uint256 scheduleStagesCount = _scheduleStagesCount[registrant][
            scheduleId
        ];

        if (scheduleStagesCount == 0) {
            return (0, Stage(0, 0, 0, 0, 0));
        }

        index = scheduleStagesCount - 1;
        stage = _scheduleStages[registrant][scheduleId][index];
    }

    /**
     * @dev See {IFairxyzMintStagesRegistry-viewLatestStageIndex}.
     */
    function viewLatestStageIndex(
        address registrant,
        uint256 scheduleId
    ) public view virtual override returns (uint256 index) {
        for (
            index = _scheduleStagesCount[registrant][scheduleId];
            index > 0;

        ) {
            unchecked {
                --index;
            }

            if (
                block.timestamp >
                _scheduleStages[registrant][scheduleId][index].endTime
            ) {
                return index + 1;
            }
        }

        return 0;
    }

    /**
     * @dev See {IFairxyzMintStagesRegistry-viewStage}.
     */
    function viewStage(
        address registrant,
        uint256 scheduleId,
        uint256 stageIndex
    ) external view virtual override returns (Stage memory stage) {
        if (stageIndex < _scheduleStagesCount[registrant][scheduleId]) {
            return _scheduleStages[registrant][scheduleId][stageIndex];
        }
        revert StageDoesNotExist();
    }

    // * INTERNAL * //

    /**
     * @dev Check that two stage phase limits do not overlap.
     * @dev Reverts if the phase limits overlap.
     *
     * @param previousStagePhaseLimit the phase limit of the previous stage
     * @param nextStagePhaseLimit the phase limit of the next stage which should be greater than or equal to the previous stage phase limit
     */
    function _phaseLimitsDoNotOverlap(
        uint256 previousStagePhaseLimit,
        uint256 nextStagePhaseLimit
    ) internal pure virtual {
        if (previousStagePhaseLimit == 0) {
            if (nextStagePhaseLimit != 0) {
                revert PhaseLimitsOverlap();
            }
        } else if (
            nextStagePhaseLimit > 0 &&
            nextStagePhaseLimit < previousStagePhaseLimit
        ) {
            revert PhaseLimitsOverlap();
        }
    }

    /**
     * @dev Ensures that the given stage times are sequential.
     * @dev Reverts if any of the times overlap based on the logic.
     *
     * @param threshold the minimum time e.g. used for the previous stage end time or current time
     * @param startTime the start time of the stage to check
     * @param endTime the end time of the stage to check
     */
    function _timesDoNotOverlap(
        uint256 threshold,
        uint256 startTime,
        uint256 endTime
    ) internal pure virtual {
        if (threshold == 0 || threshold >= startTime)
            revert StageTimesOverlap();

        if (endTime != 0 && endTime <= startTime) revert StageTimesOverlap();
    }

    // * PRIVATE * //

    /**
     * @dev sets a new stage for a schedule at the index specified
     * - if a stage already exists at the index, checks if it can be overwritten
     * - if it is not the first stage, checks that it correctly follows the existing previous stage
     *
     * @param registrant the address of the registrant the schedule is managed by
     * @param scheduleId the id of the schedule to set a new stage for
     * @param index the index to set the stage at
     * @param newStage the new stage data
     */
    function _setStage(
        address registrant,
        uint256 scheduleId,
        uint256 index,
        Stage memory newStage
    ) internal {
        uint256 currentTotalStages = _scheduleStagesCount[registrant][
            scheduleId
        ];

        uint256 blockTimestamp = block.timestamp;

        // Check if overwriting existing stage is possible
        if (index < currentTotalStages) {
            Stage memory existingStage = _scheduleStages[registrant][
                scheduleId
            ][index];

            // cannot edit stage that has ended
            if (
                existingStage.endTime > 0 &&
                existingStage.endTime < blockTimestamp
            ) revert StageHasEnded();

            if (existingStage.startTime <= blockTimestamp) {
                // can't edit start time if the existing stage has already started
                if (existingStage.startTime != newStage.startTime) {
                    revert StageHasAlreadyStarted();
                } else {
                    _timesDoNotOverlap(
                        newStage.startTime - 1,
                        newStage.startTime,
                        newStage.endTime
                    );
                }
            } else {
                _timesDoNotOverlap(
                    blockTimestamp,
                    newStage.startTime,
                    newStage.endTime
                );
            }
        } else {
            // the new stage is either after the existing stages, or the first without existing stages
            // only the times need to be checked, with start time compared to the block timestamp in this case
            _timesDoNotOverlap(
                blockTimestamp,
                newStage.startTime,
                newStage.endTime
            );
        }

        // Compare to existing previous stage
        if (index > 0) {
            if (index > currentTotalStages) revert SkippedStages();

            Stage memory previousStage = _scheduleStages[registrant][
                scheduleId
            ][index - 1];

            if (previousStage.endTime == 0) revert StageTimesOverlap();

            if (previousStage.endTime > blockTimestamp) {
                _timesDoNotOverlap(
                    previousStage.endTime,
                    newStage.startTime,
                    newStage.endTime
                );
                _phaseLimitsDoNotOverlap(
                    previousStage.phaseLimit,
                    newStage.phaseLimit
                );
            }
        }

        _scheduleStages[registrant][scheduleId][index] = newStage;
    }

    /**
     * @dev used to validate and store additional stages after the first in a new series of stages
     *
     * Requirements:
     * - the first stage must have already been set using `_setStage()` which has its own validations against existing stages
     *
     * @param registrant the address of the registrant the schedule is managed by
     * @param scheduleId the id of the schedule to set additional stages for
     * @param firstStageIndex the index after which to set the stages
     * @param stages data for the stages, including the first stage which has already been set
     * @param stagesCount the count of the stages (including the first) - this is passed so it doesn't have to be recalculated
     *
     * @return finalStage returns the last stage after all stages are validated, to be used in further logic in `setStages()`
     */
    function _setAdditionalStages(
        address registrant,
        uint256 scheduleId,
        uint256 firstStageIndex,
        Stage[] calldata stages,
        uint256 stagesCount
    ) internal virtual returns (Stage memory finalStage) {
        Stage memory previousStage;
        Stage memory nextStage;

        unchecked {
            uint256 i = 1;

            do {
                previousStage = stages[i - 1];
                nextStage = stages[i];

                _timesDoNotOverlap(
                    previousStage.endTime,
                    nextStage.startTime,
                    nextStage.endTime
                );
                _phaseLimitsDoNotOverlap(
                    previousStage.phaseLimit,
                    nextStage.phaseLimit
                );

                _scheduleStages[registrant][scheduleId][
                    firstStageIndex + i
                ] = nextStage;

                ++i;
            } while (i < stagesCount);
        }

        return nextStage;
    }

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}