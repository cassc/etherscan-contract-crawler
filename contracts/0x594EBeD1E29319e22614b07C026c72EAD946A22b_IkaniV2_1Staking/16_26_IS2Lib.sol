// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { SafeCastUpgradeable } from "../../../deps/oz_cu_4_7_2/SafeCastUpgradeable.sol";

import { IIkaniV2 } from "../../../nft/v2/interfaces/IIkaniV2.sol";
import { IIkaniV2Staking } from "../interfaces/IIkaniV2Staking.sol";
import { MinHeap } from "../lib/MinHeap.sol";

library IS2Lib {
    using MinHeap for MinHeap.Heap;
    using SafeCastUpgradeable for uint256;

    //---------------- Constants ----------------//

    uint256 internal constant MULTIPLIER_BASE = 1e6;
    uint256 internal constant MULTIPLIER_BASE_2 = MULTIPLIER_BASE ** 2;

    uint256 internal constant BASE_POINTS_NO_FOIL = 1e6;
    uint256 internal constant BASE_POINTS_GOLD = 1.5e6;
    uint256 internal constant BASE_POINTS_PLATINUM = 2.25e6;
    uint256 internal constant BASE_POINTS_SUI_GENERIS = 3.375e6;

    uint256 internal constant SEASONS_MULTIPLIER_2 = 1.05e6;
    uint256 internal constant SEASONS_MULTIPLIER_3 = 1.12e6;
    uint256 internal constant SEASONS_MULTIPLIER_4 = 1.25e6;

    uint256 internal constant FABRICS_MULTIPLIER_2 = 1.05e6;
    uint256 internal constant FABRICS_MULTIPLIER_3 = 1.12e6;
    uint256 internal constant FABRICS_MULTIPLIER_4 = 1.25e6;

    uint256 internal constant LEVEL_MULTIPLIER_1 = 1.05e6;
    uint256 internal constant LEVEL_MULTIPLIER_2 = 1.1e6;
    uint256 internal constant LEVEL_MULTIPLIER_3 = 1.2e6;
    uint256 internal constant LEVEL_MULTIPLIER_4 = 1.3e6;

    uint256 internal constant LEVEL_DURATION_1 = 1 weeks;
    uint256 internal constant LEVEL_DURATION_2 = 2 weeks;
    uint256 internal constant LEVEL_DURATION_3 = 4 weeks;
    uint256 internal constant LEVEL_DURATION_4 = 12 weeks;

    uint256 internal constant LAST_LEVEL = 4;

    //---------------- External Functions ----------------//

    /**
     * @dev Settle rewards to current timestamp, returning updated context and new rewards.
     *
     *  After calling this function, the returned updated context should be saved to storage.
     *  The new rewards should also be saved to storage (or spent).
     */
    function settleAccountAndGetOwedRewards(
        IIkaniV2Staking.SettlementContext memory intialContext,
        mapping(uint256 => IIkaniV2Staking.RateChange) storage _rate_changes_,
        MinHeap.Heap storage _checkpoints_,
        mapping(uint256 => IIkaniV2Staking.TokenStakingState) storage _token_staking_state_,
        uint256 globalNumRateChanges
    )
        external
        returns (
            IIkaniV2Staking.SettlementContext memory context,
            uint256 newRewards
        )
    {
        context = intialContext;
        newRewards = 0;

        if (context.timestamp == block.timestamp) {
            // Short-circuit.
            return (context, newRewards);
        }

        if (context.points == 0) {
            // Short-circuit.
            //
            // TODO: Clarify the note below.
            //
            // Note: We don't remove old checkpoints from the heap at this time. It's important
            // that any old checkpoints are invalidated by the change in staking nonce, otherwise
            // this function would revert when trying to settle a checkpoint whose timestamp is
            // less than the context timestamp.
            context.timestamp = block.timestamp.toUint32();
            context.numRateChanges = globalNumRateChanges.toUint32();

            // Get the current base rate.
            context.baseRate = _rate_changes_[globalNumRateChanges].baseRate;

            return (context, newRewards);
        }

        // Load into memory any rate changes that need to be applied.
        uint256 numRateChangesToApply = globalNumRateChanges - context.numRateChanges;
        IIkaniV2Staking.RateChange[] memory rateChanges = (
            new IIkaniV2Staking.RateChange[](numRateChangesToApply)
        );
        for (uint256 i = 0; i < numRateChangesToApply;) {
            unchecked {
                rateChanges[i] = _rate_changes_[context.numRateChanges + i + 1];
                ++i;
            }
        }

        // Iterate over the checkpoints in chronological order.
        while (_checkpoints_.length > 0) {
            IIkaniV2Staking.Checkpoint memory checkpoint;

            {
                uint256 checkpointUint = _checkpoints_.unsafePeek();

                // Get the threshold for checkpoints that have been reached.
                uint256 checkpointThreshold;
                unchecked {
                    checkpointThreshold = (block.timestamp + 1) << 224;
                }

                // Stop iterating if the next checkpoint has not been reached.
                if (checkpointUint >= checkpointThreshold) {
                    break;
                }

                // If the checkpoint was reached, remove it from the heap and process it.
                _checkpoints_.popMin();

                // Parse the checkpoint.
                checkpoint = _decodeCheckpoint(checkpointUint);
            }

            // Ignore and discard the checkpoint if it is no longer valid.
            // A checkpoint is no longer valid if the associated token was unstaked since the
            // checkpoint was created.
            {
                // TODO: Optimize by caching these?
                IIkaniV2Staking.TokenStakingState memory stakingState = (
                    _token_staking_state_[checkpoint.tokenId]
                );
                if (checkpoint.stakedNonce != stakingState.nonce) {
                    continue;
                }
                if (stakingState.timestamp == 0) {
                    // TODO: Remove.
                    //
                    // This check is redundant, and this continue should never be reached.
                    // Keeping it just for now.
                    // revert('Sanity check failed');
                    continue;
                }
            }

            // Process any rate changes that occurred before the checkpoint.
            while (context.numRateChanges < globalNumRateChanges) {
                uint256 rateIndex = (
                    numRateChangesToApply + context.numRateChanges - globalNumRateChanges
                );

                if (rateChanges[rateIndex].timestamp >= checkpoint.timestamp) {
                    break;
                }

                newRewards += _settleAccountToTimestamp(context, rateChanges[rateIndex].timestamp);
                context.timestamp = rateChanges[rateIndex].timestamp;

                context.baseRate = rateChanges[rateIndex].baseRate;
                ++context.numRateChanges;
            }

            // Settle up to the checkpoint timestamp.
            newRewards += _settleAccountToTimestamp(context, checkpoint.timestamp);
            context.timestamp = checkpoint.timestamp;

            // Add points from the checkpoint.
            uint256 level = uint256(checkpoint.level);
            uint256 bonusPoints;
            {
                bonusPoints = _getBonusPointsFromLevel(
                    uint256(checkpoint.basePoints),
                    level
                ).toUint32();
            }
            {
                context.points += bonusPoints.toUint32();
            }

            // Add next checkpoint if there is a next checkpoint.
            if (level < LAST_LEVEL) {
                checkpoint = _getNextCheckpoint(checkpoint);
                _insertCheckpoint(_checkpoints_, checkpoint);
            }
        }

        // Process any remaining rate changes and settle up to each one.
        while (context.numRateChanges < globalNumRateChanges) {
            IIkaniV2Staking.RateChange memory rateChange = rateChanges[
                numRateChangesToApply + context.numRateChanges - globalNumRateChanges
            ];

            newRewards += _settleAccountToTimestamp(context, rateChange.timestamp);
            context.timestamp = rateChange.timestamp;

            context.baseRate = rateChange.baseRate;
            ++context.numRateChanges;
        }

        // Settle up to the current timestamp.
        newRewards += _settleAccountToTimestamp(context, block.timestamp);
        context.timestamp = block.timestamp.toUint32();
    }

    function stakeLogic(
        IIkaniV2Staking.SettlementContext memory intialContext,
        IIkaniV2.PoemTraits memory traits,
        uint256 stakingStartTimestamp,
        uint256 stakedNonce,
        uint256 tokenId
    )
        external
        view
        returns (
            IIkaniV2Staking.SettlementContext memory context,
            IIkaniV2Staking.Checkpoint memory checkpoint
        )
    {
        context = intialContext;

        // Get base points (affected by foil).
        uint256 basePoints = getFoilRewardsMultiplier(traits);

        // Determine level and points (affected by staked duration).
        uint256 stakedDuration = block.timestamp - stakingStartTimestamp;
        uint256 level = getLevelForStakedDuration(stakedDuration);
        uint256 points = (
            basePoints *
            _getLevelRewardsMultiplier(level) /
            MULTIPLIER_BASE
        );

        // If applicable, add a checkpoint for the next increase in points.
        if (level < LAST_LEVEL) {
            uint256 nextLevel;
            unchecked {
                nextLevel = level + 1;
            }
            uint256 checkpointTimestamp = stakingStartTimestamp + _getDurationForLevel(nextLevel);
            checkpoint = IIkaniV2Staking.Checkpoint({
                timestamp: checkpointTimestamp.toUint32(),
                level: nextLevel.toUint32(),
                basePoints: basePoints.toUint32(),
                stakedNonce: stakedNonce.toUint32(),
                tokenId: tokenId.toUint128()
            });
        }

        // Update the trait counts, acount-level multiplier, and points for the account.
        context = _addTraitsToToken(context, traits);
        context.multiplier = getAccountRewardsMultiplier(context).toUint32();
        context.points += points.toUint32();
    }

    function unstakeLogic(
        IIkaniV2Staking.SettlementContext memory intialContext,
        IIkaniV2.PoemTraits memory traits,
        uint256 stakedTimestamp
    )
        external
        view
        returns (
            IIkaniV2Staking.SettlementContext memory context
        )
    {
        context = intialContext;

        // Get base points (affected by foil).
        uint256 basePoints = getFoilRewardsMultiplier(traits);

        // Determine points (affected by staked duration).
        uint256 stakedDuration = block.timestamp - stakedTimestamp;
        uint256 points = (
            basePoints *
            getStakedDurationRewardsMultiplier(stakedDuration) /
            MULTIPLIER_BASE
        );

        // Update the trait counts, acount-level multiplier, and points for the account.
        context = _subtractTraitsFromToken(context, traits);
        context.multiplier = getAccountRewardsMultiplier(context).toUint32();
        context.points -= points.toUint32();

    }

    //---------------- Public State-Changing Functions ----------------//

    function _insertCheckpoint(
        MinHeap.Heap storage _checkpoints_,
        IIkaniV2Staking.Checkpoint memory checkpoint
    )
        public
    {
        uint256 checkpointUint = (
            (uint256(checkpoint.timestamp) << 224) +
            (uint256(checkpoint.level) << 192) +
            (uint256(checkpoint.basePoints) << 160) +
            (uint256(checkpoint.stakedNonce) << 128) +
            checkpoint.tokenId
        );
        _checkpoints_.insert(checkpointUint);
    }

    //---------------- Public Pure Functions ----------------//

    function getFoilRewardsMultiplier(
        IIkaniV2.PoemTraits memory traits
    )
        public
        pure
        returns (uint256)
    {
        if (traits.foil == IIkaniV2.Foil.NONE) {
            return BASE_POINTS_NO_FOIL;
        } else if (traits.foil == IIkaniV2.Foil.GOLD) {
            return BASE_POINTS_GOLD;
        } else if (traits.foil == IIkaniV2.Foil.PLATINUM) {
            return BASE_POINTS_PLATINUM;
        } else if (traits.foil == IIkaniV2.Foil.SUI_GENERIS) {
            return BASE_POINTS_SUI_GENERIS;
        }

        // Sanity check.
        revert("Unknown foil");
    }

    function getStakedDurationRewardsMultiplier(
        uint256 stakedDuration
    )
        public
        pure
        returns (uint256)
    {
        if (stakedDuration < LEVEL_DURATION_1) {
            return MULTIPLIER_BASE;
        } else if (stakedDuration < LEVEL_DURATION_2) {
            return LEVEL_MULTIPLIER_1;
        } else if (stakedDuration < LEVEL_DURATION_3) {
            return LEVEL_MULTIPLIER_2;
        } else if (stakedDuration < LEVEL_DURATION_4) {
            return LEVEL_MULTIPLIER_3;
        }
        return LEVEL_MULTIPLIER_4;
    }

    function getAccountRewardsMultiplier(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        uint256 fabricsMultiplier = getFabricsRewardsMultiplier(context);
        uint256 seasonsMultiplier = getSeasonsRewardsMultiplier(context);
        return fabricsMultiplier * seasonsMultiplier / MULTIPLIER_BASE;
    }

    function getFabricsRewardsMultiplier(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        uint256 uniqueFabricsCount = getNumFabricsStaked(context);
        if (uniqueFabricsCount == 4)  {
            return FABRICS_MULTIPLIER_4;
        } else if (uniqueFabricsCount == 3)  {
            return FABRICS_MULTIPLIER_3;
        } else if (uniqueFabricsCount == 2)  {
            return FABRICS_MULTIPLIER_2;
        }
        return MULTIPLIER_BASE;
    }

    function getSeasonsRewardsMultiplier(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        uint256 uniqueSeasonsCount = getNumSeasonsStaked(context);
        if (uniqueSeasonsCount == 4)  {
            return SEASONS_MULTIPLIER_4;
        } else if (uniqueSeasonsCount == 3)  {
            return SEASONS_MULTIPLIER_3;
        } else if (uniqueSeasonsCount == 2)  {
            return SEASONS_MULTIPLIER_2;
        }
        return MULTIPLIER_BASE;
    }

    function getNumFabricsStaked(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        unchecked {
            return (
                _toUint256(context.fabricKoyamaki > 0) +
                _toUint256(context.fabricSeigaiha > 0) +
                _toUint256(context.fabricNami > 0) +
                _toUint256(context.fabricKumo > 0)
            );
        }
    }

    function getNumSeasonsStaked(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        unchecked {
            return (
                _toUint256(context.seasonSpring > 0) +
                _toUint256(context.seasonSummer > 0) +
                _toUint256(context.seasonAutumn > 0) +
                _toUint256(context.seasonWinter > 0)
            );
        }
    }

    function getLevelForStakedDuration(
        uint256 stakedDuration
    )
        public
        pure
        returns (uint256)
    {
        if (stakedDuration < LEVEL_DURATION_1) {
            return 0;
        } else if (stakedDuration < LEVEL_DURATION_2) {
            return 1;
        } else if (stakedDuration < LEVEL_DURATION_3) {
            return 2;
        } else if (stakedDuration < LEVEL_DURATION_4) {
            return 3;
        }
        return LAST_LEVEL; // 4
    }

    //---------------- Private Pure Functions ----------------//

    function _getLevelRewardsMultiplier(
        uint256 level
    )
        private
        pure
        returns (uint256)
    {
        if (level == 0) {
            return MULTIPLIER_BASE;
        } else if (level == 1) {
            return LEVEL_MULTIPLIER_1;
        } else if (level == 2) {
            return LEVEL_MULTIPLIER_2;
        } else if (level == 3) {
            return LEVEL_MULTIPLIER_3;
        } else if (level == 4) {
            return LEVEL_MULTIPLIER_4;
        }

        // Sanity check.
        revert("Unknown level");
    }

    function _getDurationForLevel(
        uint256 level
    )
        private
        pure
        returns (uint256)
    {
        // Note: This function cannot be called with level = 0.
        if (level == 1) {
            return LEVEL_DURATION_1;
        } else if (level == 2) {
            return LEVEL_DURATION_2;
        } else if (level == 3) {
            return LEVEL_DURATION_3;
        } else if (level == 4) {
            return LEVEL_DURATION_4;
        }

        // Sanity check.
        revert("Unknown level");
    }

    function _addTraitsToToken(
        IIkaniV2Staking.SettlementContext memory context,
        IIkaniV2.PoemTraits memory traits
    )
        private
        pure
        returns (IIkaniV2Staking.SettlementContext memory)
    {
        // TODO: Optimize.
        context.seasonSpring += _toUint8(traits.season == IIkaniV2.Season.SPRING);
        context.seasonSummer += _toUint8(traits.season == IIkaniV2.Season.SUMMER);
        context.seasonAutumn += _toUint8(traits.season == IIkaniV2.Season.AUTUMN);
        context.seasonWinter += _toUint8(traits.season == IIkaniV2.Season.WINTER);
        context.fabricKoyamaki += _toUint8(traits.fabric == IIkaniV2.Fabric.KOYAMAKI);
        context.fabricSeigaiha += _toUint8(traits.fabric == IIkaniV2.Fabric.SEIGAIHA);
        context.fabricNami += _toUint8(traits.fabric == IIkaniV2.Fabric.NAMI);
        context.fabricKumo += _toUint8(traits.fabric == IIkaniV2.Fabric.KUMO);

        return context;
    }

    function _subtractTraitsFromToken(
        IIkaniV2Staking.SettlementContext memory context,
        IIkaniV2.PoemTraits memory traits
    )
        private
        pure
        returns (IIkaniV2Staking.SettlementContext memory)
    {
        // TODO: Optimize.
        context.seasonSpring -= _toUint8(traits.season == IIkaniV2.Season.SPRING);
        context.seasonSummer -= _toUint8(traits.season == IIkaniV2.Season.SUMMER);
        context.seasonAutumn -= _toUint8(traits.season == IIkaniV2.Season.AUTUMN);
        context.seasonWinter -= _toUint8(traits.season == IIkaniV2.Season.WINTER);
        context.fabricKoyamaki -= _toUint8(traits.fabric == IIkaniV2.Fabric.KOYAMAKI);
        context.fabricSeigaiha -= _toUint8(traits.fabric == IIkaniV2.Fabric.SEIGAIHA);
        context.fabricNami -= _toUint8(traits.fabric == IIkaniV2.Fabric.NAMI);
        context.fabricKumo -= _toUint8(traits.fabric == IIkaniV2.Fabric.KUMO);

        return context;
    }

    function _settleAccountToTimestamp(
        IIkaniV2Staking.SettlementContext memory context,
        uint256 timestamp
    )
        private
        pure
        returns (uint256)
    {
        uint256 timeDelta = timestamp - context.timestamp;
        uint256 rewards = (
            timeDelta *
            context.baseRate *
            context.points *
            context.multiplier /
            MULTIPLIER_BASE_2
        );

        return rewards;
    }

    function _getNextCheckpoint(
        IIkaniV2Staking.Checkpoint memory checkpoint
    )
        private
        pure
        returns (IIkaniV2Staking.Checkpoint memory)
    {
        // Assumption: checkpoint.level < LAST_LEVEL
        uint256 timestampDiff;
        unchecked {
            uint32 newLevel = ++checkpoint.level;
            if (newLevel == 2) {
                timestampDiff = LEVEL_DURATION_2 - LEVEL_DURATION_1;
            } else if (newLevel == 3) {
                timestampDiff = LEVEL_DURATION_3 - LEVEL_DURATION_2;
            } else if (newLevel == 4) {
                timestampDiff = LEVEL_DURATION_4 - LEVEL_DURATION_3;
            }
        }
        checkpoint.timestamp += timestampDiff.toUint32();
        return checkpoint;
    }

    function _getBonusPointsFromLevel(
        uint256 basePoints,
        uint256 level
    )
        private
        pure
        returns (uint256)
    {
        // example params:
        //              no foil: base points 1e6
        //                 gold: base points 1.2e6
        //   level 1 multiplier: 1.1e6
        //   level 2 multiplier: 1.2e6
        //                 base: 1e6
        //
        // then the bonus points that are unlocked are
        //
        // no foil, level 1: (1.1e6 - 1.0e6) * 1e6 / base = 0.1e6
        // no foil, level 2: (1.2e6 - 1.1e6) * 1e6 / base = 0.1e6
        //    gold, level 1: (1.1e6 - 1.0e6) * 1.2e6 / base = 0.12e6
        //    gold, level 2: (1.2e6 - 1.1e6) * 1.2e6 / base = 0.12e6
        //
        // result:
        //   no foil: 1e6 -> 1.1e6 -> 1.2e6
        //      gold: 1.2e6 -> 1.32e6 -> 1.44e6
        //
        // Assume this function will not be called with level = 0.
        uint256 diff = (
            _getLevelRewardsMultiplier(level) -
            _getLevelRewardsMultiplier(level - 1)
        );
        return basePoints * diff / MULTIPLIER_BASE;
    }

    function _decodeCheckpoint(
        uint256 checkpointUint
    )
        private
        pure
        returns (
            IIkaniV2Staking.Checkpoint memory checkpoint
        )
    {
        // Truncate (unsafe cast).
        checkpoint.timestamp = uint32(checkpointUint >> 224);
        checkpoint.level = uint32(checkpointUint >> 192);
        checkpoint.basePoints = uint32(checkpointUint >> 160);
        checkpoint.stakedNonce = uint32(checkpointUint >> 128);
        checkpoint.tokenId = uint128(checkpointUint);
    }

    function _toUint8(bool x)
        private
        pure
        returns (uint8 r)
    {
        assembly { r := x }
    }

    function _toUint256(bool x)
        private
        pure
        returns (uint256 r)
    {
        assembly { r := x }
    }
}