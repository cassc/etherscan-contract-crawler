// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Stake library used by ILV pool and Sushi LP Pool.
 *
 * @dev Responsible to manage weight calculation and store important constants
 *      related to stake period, base weight and multipliers utilized.
 */
library Stake {
    struct Data {
        /// @dev token amount staked
        uint120 value;
        /// @dev locking period - from
        uint64 lockedFrom;
        /// @dev locking period - until
        uint64 lockedUntil;
        /// @dev indicates if the stake was created as a yield reward
        bool isYield;
    }

    /**
     * @dev Stake weight is proportional to stake value and time locked, precisely
     *      "stake value wei multiplied by (fraction of the year locked plus one)".
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e6 constant, as an integer.
     * @dev Corner case 1: if time locked is zero, weight is stake value multiplied by 1e6 + base weight
     * @dev Corner case 2: if time locked is two years, division of
            (lockedUntil - lockedFrom) / MAX_STAKE_PERIOD is 1e6, and
     *      weight is a stake value multiplied by 2 * 1e6.
     */
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    /**
     * @dev Minimum weight value, if result of multiplication using WEIGHT_MULTIPLIER
     *      is 0 (e.g stake flexible), then BASE_WEIGHT is used.
     */
    uint256 internal constant BASE_WEIGHT = 1e6;
    /**
     * @dev Minimum period that someone can lock a stake for.
     */
    uint256 internal constant MIN_STAKE_PERIOD = 30 days;

    /**
     * @dev Maximum period that someone can lock a stake for.
     */
    uint256 internal constant MAX_STAKE_PERIOD = 365 days;

    /**
     * @dev Rewards per weight are stored multiplied by 1e20 as uint.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e20;

    /**
     * @dev When we know beforehand that staking is done for yield instead of
     *      executing `weight()` function we use the following constant.
     */
    uint256 internal constant YIELD_STAKE_WEIGHT_MULTIPLIER = 2 * 1e6;

    function weight(Data storage _self) internal view returns (uint256) {
        return
            uint256(
                (((_self.lockedUntil - _self.lockedFrom) * WEIGHT_MULTIPLIER) / MAX_STAKE_PERIOD + BASE_WEIGHT) *
                    _self.value
            );
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      ILV reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param _rewardPerWeight ILV reward per weight
     * @param _rewardPerWeightPaid last reward per weight value used for user earnings
     * @return reward value normalized to 10^12
     */
    function earned(
        uint256 _weight,
        uint256 _rewardPerWeight,
        uint256 _rewardPerWeightPaid
    ) internal pure returns (uint256) {
        // apply the formula and return
        return (_weight * (_rewardPerWeight - _rewardPerWeightPaid)) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward ILV value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward.
     *      - OR -
     * @dev Converts reward ILV value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight.
     *
     * @param _reward yield reward
     * @param _globalWeight total weight in the pool
     * @return reward per weight value
     */
    function getRewardPerWeight(uint256 _reward, uint256 _globalWeight) internal pure returns (uint256) {
        // apply the reverse formula and return
        return (_reward * REWARD_PER_WEIGHT_MULTIPLIER) / _globalWeight;
    }
}