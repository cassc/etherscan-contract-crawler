// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "IConicPool.sol";

interface IRebalancingRewardsHandler {
    event RebalancingRewardDistributed(
        address indexed pool,
        address indexed account,
        address indexed token,
        uint256 tokenAmount
    );

    /// @notice Handles the rewards distribution for the rebalancing of the pool
    /// @param conicPool The pool that is being rebalanced
    /// @param account The account that is rebalancing the pool
    /// @param deviationBefore The total absolute deviation of the Conic pool before the rebalancing
    /// @param deviationAfter The total absolute deviation of the Conic pool after the rebalancing
    function handleRebalancingRewards(
        IConicPool conicPool,
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external;
}