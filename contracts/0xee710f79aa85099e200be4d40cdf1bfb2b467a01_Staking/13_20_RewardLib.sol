// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SafeCast} from "./SafeCast.sol";
import {StakingPoolLib} from "./StakingPoolLib.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

library RewardLib {
    using SafeCast for uint256;

    /// @notice emitted when the reward is initialized for the first time
    /// @param available the amount of rewards available for distribution in the
    /// staking pool
    /// @param startTimestamp the start timestamp when rewards are started
    /// @param endTimestamp the timestamp when the reward will run out
    event RewardInitialized(uint256 available, uint256 startTimestamp, uint256 endTimestamp);
    /// @notice emitted when owner adds more rewards to the pool
    /// @param amountAdded the amount of ARPA rewards added to the pool
    /// @param endTimestamp the timestamp when the reward will run out
    event RewardAdded(uint256 amountAdded, uint256 endTimestamp);
    /// @notice emitted when owner withdraws leftover rewards
    /// @param amount the amount of rewards withdrawn
    event RewardWithdrawn(uint256 amount);
    /// @notice emitted when an  operator gets slashed.
    /// Node operators are not slashed more than the amount of rewards they
    /// have earned.
    event RewardSlashed(address[] operator, uint256[] slashedDelegatedRewards);

    /// @notice This error is thrown when the updated reward duration is too short
    error RewardDurationTooShort();

    /// @notice This is the reward calculation precision variable. ARPA token has the
    /// 1e18 multiplier which means that rewards are floored after 6 decimals
    /// points. Micro ARPA is the smallest unit that is eligible for rewards.
    uint256 internal constant REWARD_PRECISION = 1e12;

    struct DelegatedRewards {
        // Count of delegates who are eligible for a share of a reward
        uint8 delegatesCount;
        // Tracks base reward amounts that goes to an operator as delegation rewards.
        // Used to correctly account for any changes in operator count, delegated amount, or reward rate.
        uint96 cumulativePerDelegate;
        // Timestamp of the last time accumulate was called
        // `startTimestamp` <= `delegated.lastAccumulateTimestamp`
        uint32 lastAccumulateTimestamp;
    }

    struct BaseRewards {
        // Count of community stakers who are eligible for a share of a reward
        uint32 communityStakersCount;
        // The cumulative ARPA accrued per stake from past reward rates
        // expressed in ARPA wei per micro ARPA
        uint96 cumulativePerShare;
        // Timestamp of the last time the base reward rate was accumulated
        uint32 lastAccumulateTimestamp;
    }

    struct MissedRewards {
        // Tracks missed base rewards that are deducted from late stakers
        uint96 base;
        // Tracks missed delegation rewards that are deducted from late delegates
        uint96 delegated;
    }

    struct Reward {
        mapping(address => MissedRewards) missed;
        DelegatedRewards delegated;
        BaseRewards base;
        // Reward rate expressed in arpa weis per second
        uint80 rate;
        // Timestamp when the reward stops accumulating. Has to support a very long
        // duration for scenarios with low reward rate.
        // `endTimestamp` >= `startTimestamp`
        uint32 endTimestamp;
        // Timestamp when the reward comes into effect
        // `startTimestamp` <= `endTimestamp`
        uint32 startTimestamp;
    }

    /// @notice initializes the reward with the defined parameters
    /// @param minRewardDuration the minimum duration rewards need to last for
    /// @param newReward the amount of rewards to be added to the pool
    /// @param rewardDuration the duration for which the reward will be distributed
    function _initialize(Reward storage reward, uint256 minRewardDuration, uint256 newReward, uint256 rewardDuration)
        internal
    {
        uint32 blockTimestamp = block.timestamp._toUint32();
        reward.startTimestamp = blockTimestamp;

        reward.delegated.lastAccumulateTimestamp = blockTimestamp;
        reward.base.lastAccumulateTimestamp = blockTimestamp;

        _updateReward(reward, newReward, rewardDuration, minRewardDuration);

        emit RewardInitialized(newReward, reward.startTimestamp, reward.endTimestamp);
    }

    /// @return bool true if the reward is expired (end <= now)
    function _isDepleted(Reward storage reward) internal view returns (bool) {
        return reward.endTimestamp <= block.timestamp;
    }

    /// @notice Helper function to accumulate base rewards
    /// Accumulate reward per micro ARPA before changing reward rate.
    /// This keeps rewards prior to rate change unaffected.
    function _accumulateBaseRewards(Reward storage reward, uint256 totalStakedAmount) internal {
        reward.base.cumulativePerShare = _calculateCumulativeBaseRewards(reward, totalStakedAmount)._toUint96();
        reward.base.lastAccumulateTimestamp = _getCappedTimestamp(reward)._toUint32();
    }

    /// @notice Helper function to accumulate delegation rewards
    /// @dev This function is necessary to correctly account for any changes in
    /// eligible operators, delegated amount or reward rate.
    function _accumulateDelegationRewards(
        Reward storage reward,
        uint256 totalDelegatedAmount,
        uint256 totalStakedAmount
    ) internal {
        reward.delegated.cumulativePerDelegate =
            _calculateCumulativeDelegatedRewards(reward, totalDelegatedAmount, totalStakedAmount)._toUint96();
        reward.delegated.lastAccumulateTimestamp = _getCappedTimestamp(reward)._toUint32();
    }

    function _calculateCumulativeBaseRewards(Reward storage reward, uint256 totalStakedAmount)
        internal
        view
        returns (uint256)
    {
        if (totalStakedAmount == 0) return reward.base.cumulativePerShare;
        uint256 elapsedDurationSinceLastAccumulate = _isDepleted(reward)
            ? (uint256(reward.endTimestamp) - uint256(reward.base.lastAccumulateTimestamp))
            : block.timestamp - uint256(reward.base.lastAccumulateTimestamp);

        return reward.base.cumulativePerShare
            + (uint256(reward.rate) * elapsedDurationSinceLastAccumulate * REWARD_PRECISION / totalStakedAmount)._toUint96();
    }

    function _calculateCumulativeDelegatedRewards(
        Reward storage reward,
        uint256 totalDelegatedAmount,
        uint256 totalStakedAmount
    ) internal view returns (uint256) {
        if (totalStakedAmount == 0) return reward.delegated.cumulativePerDelegate;
        uint256 elapsedDurationSinceLastAccumulate = _isDepleted(reward)
            ? uint256(reward.endTimestamp) - uint256(reward.delegated.lastAccumulateTimestamp)
            : block.timestamp - uint256(reward.delegated.lastAccumulateTimestamp);

        return reward.delegated.cumulativePerDelegate
            + (
                uint256(reward.rate) * elapsedDurationSinceLastAccumulate * totalDelegatedAmount / totalStakedAmount
                    / Math.max(uint256(reward.delegated.delegatesCount), 1)
            )._toUint96();
    }

    /// @notice Calculates the amount of delegated rewards accumulated so far.
    /// @dev This function takes into account the amount of delegated
    /// rewards accumulated from previous delegate counts and amounts and
    /// the latest additional value.
    function _calculateAccruedDelegatedRewards(
        Reward storage reward,
        uint256 totalDelegatedAmount,
        uint256 totalStakedAmount
    ) internal view returns (uint256) {
        return _calculateCumulativeDelegatedRewards(reward, totalDelegatedAmount, totalStakedAmount);
    }

    /// @notice Calculates the amount of rewards accrued so far.
    /// @dev This function takes into account the amount of
    /// rewards accumulated from previous rates in addition to
    /// the rewards that will be accumulated based off the current rate
    /// over a given duration.
    function _calculateAccruedBaseRewards(Reward storage reward, uint256 amount, uint256 totalStakedAmount)
        internal
        view
        returns (uint256)
    {
        return amount * _calculateCumulativeBaseRewards(reward, totalStakedAmount) / REWARD_PRECISION;
    }

    /// @notice calculates an amount that community stakers have to delegate to operators
    /// @param amount base staked amount to calculate delegated amount against
    /// @param delegationRateDenominator Delegation rate used to calculate delegated stake amount
    function _getDelegatedAmount(uint256 amount, uint256 delegationRateDenominator) internal pure returns (uint256) {
        return amount / delegationRateDenominator;
    }

    /// @notice calculates the amount of stake that remains after accounting for delegation requirement
    /// @param amount base staked amount to calculate non-delegated amount against
    /// @param delegationRateDenominator Delegation rate used to calculate delegated stake amount
    function _getNonDelegatedAmount(uint256 amount, uint256 delegationRateDenominator)
        internal
        pure
        returns (uint256)
    {
        return amount - _getDelegatedAmount(amount, delegationRateDenominator);
    }

    /// @notice This function is called when the staking pool is initialized,
    /// rewards are added, TODO and an alert is raised
    /// @param newReward new reward amount
    /// @param rewardDuration duration of the reward
    function _updateReward(Reward storage reward, uint256 newReward, uint256 rewardDuration, uint256 minRewardDuration)
        internal
    {
        uint256 remainingRewards =
            (_isDepleted(reward) ? 0 : (reward.rate * (uint256(reward.endTimestamp) - block.timestamp))) + newReward;

        // Validate that the new reward duration is at least the min reward duration.
        // This is a safety mechanism to guard against operational mistakes.
        if (rewardDuration < minRewardDuration) {
            revert RewardDurationTooShort();
        }

        reward.endTimestamp = (block.timestamp + rewardDuration)._toUint32();
        reward.rate = (remainingRewards / rewardDuration)._toUint80();
    }

    /// @return The amount of delegated rewards an operator
    /// has earned.
    function _getOperatorEarnedDelegatedRewards(
        Reward storage reward,
        address operator,
        uint256 totalDelegatedAmount,
        uint256 totalStakedAmount
    ) internal view returns (uint256) {
        return _calculateAccruedDelegatedRewards(reward, totalDelegatedAmount, totalStakedAmount)
            - uint256(reward.missed[operator].delegated);
    }

    /// @return The current timestamp or, if the current timestamp has passed reward
    /// end timestamp, reward end timestamp.
    /// @dev This is necessary to ensure that rewards are calculated correctly
    /// after the reward is depleted.
    function _getCappedTimestamp(Reward storage reward) internal view returns (uint256) {
        return Math.min(uint256(reward.endTimestamp), block.timestamp);
    }
}