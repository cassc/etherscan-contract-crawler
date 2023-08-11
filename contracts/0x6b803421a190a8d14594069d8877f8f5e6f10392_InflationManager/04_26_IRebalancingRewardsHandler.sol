// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "../pools/ITorusPool.sol";

interface IRebalancingRewardsHandler {
    event RebalancingRewardDistributed(
        address indexed pool,
        address indexed account,
        address indexed token,
        uint256 tokenAmount
    );

    /// @notice Handles the rewards distribution for the rebalancing of the pool
    /// @param torusPool The pool that is being rebalanced
    /// @param account The account that is rebalancing the pool
    /// @param deviationBefore The total absolute deviation of the Torus pool before the rebalancing
    /// @param deviationAfter The total absolute deviation of the Torus pool after the rebalancing
    function handleRebalancingRewards(
        ITorusPool torusPool,
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external;
}