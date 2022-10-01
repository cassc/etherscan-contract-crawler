// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./Math.sol";
import "./Percentage.sol";

library GRPDependantRewardProfile {
    /**
     * @dev Computes rewards emitted by a node based on its lifetime.
     *
     * @param price Price of this type of node
     * @param baseRewardsPerSecond Base reward emitted per second
     * @param lastKnownLifetime Last known lifetime of the node instance
     * @param duration Time window on which we compute the rewards (in seconds)
     * @return rewards The computed rewards
     *
     * Implementation details :
     *
     * Every node has an implicit lifetime (implicit in the sense that we
     * can't update the node's state on the storage each passing second, so
     * we compute it on the fly). The lifetime expresses the number of
     * seconds remaining until the node is considered to be "dried out".
     *
     * We can therefore represent the emitted rewards as a function of the
     * lifetime : {https://cutt.ly/XGWNa0R} (`r` the time needed to reach the
     * GRP and `b` the base rewards of the node).
     * This reward function returns the rewards emitted every second at a
     * given point in the node's lifetime. This specific function is centered
     * around 0, so we can shift it to the correct point in the lifetime, 0
     * being the point in time when the node is dried out.
     *
     * Now to get the emitted rewards during any given lifetime window, we
     * can simply integrate the reward function over that window. In our case,
     * we want to compute the rewards from the last known lifetime until now
     * (left as a parameter, as `duration`). First, we shift the rewards
     * function to the last known lifetime :
     * {https://cutt.ly/OGWNdVW} (`l` is the actual node lifetime).
     * Then, we can integrate this function from `0` to `duration` :
     * {https://cutt.ly/aGWNhjH} (`x` is our `duration`).
     *
     * Graphing these functions might help to understand the math :
     * {https://www.desmos.com/calculator/cef8wqp4ef}
     */
    function integrateRewardsFromLifetime(
        uint256 price,
        uint256 baseRewardsPerSecond,
        uint256 lastKnownLifetime,
        uint256 duration
    ) internal pure returns (uint256 rewards) {
        uint256 b = baseRewardsPerSecond;
        uint256 r = price / baseRewardsPerSecond;
        uint256 l = lastKnownLifetime;
        uint256 t = duration;

        uint256 res =
            (
                b *
                (
                    19 * Math.min(t, Math.subOrZero(l, r))
                    + Math.min(t, Math.max(l, Math.subOrZero(l, r)))
                )
            ) / 20;
        
        return res;
    }

    function getRewardsPerSecondsAtGivenLifetime(
        uint256 price,
        uint256 baseRewardsPerSecond,
        uint256 lifetime
    ) internal pure returns (uint256 rewardsPerSecond) {
        uint256 b = baseRewardsPerSecond;
        uint256 r = price / baseRewardsPerSecond;
        uint256 l = lifetime;

        if (l > r) {
            return b;
        } else if (l < 0) {
            return 0;
        } else {
            return b/20;
        }
    }

    /// @dev Computes the rewards emitted by a fertilizer based on the time
    /// passed since its activation.
    ///
    /// @param baseRewardsPerSecond Base reward emitted per second
    /// @param percentageOfBaseRewards Percentage of the base rewards of the
    /// fertilizer
    /// @param effectDuration Duration of the effect of the fertilizer
    /// @param lifetimeSinceActivation Time since the fertilizer was activated
    ///
    /// @return The computed rewards
    function integrateFertilizerAdditionalRewards(
        uint256 baseRewardsPerSecond,
        uint256 percentageOfBaseRewards,
        uint256 effectDuration,
        uint256 lifetimeSinceActivation
    )
        internal
        pure
        returns (uint256)
    {
        return Percentages.times(percentageOfBaseRewards, baseRewardsPerSecond) *
            Math.min(lifetimeSinceActivation, effectDuration);
    }
}