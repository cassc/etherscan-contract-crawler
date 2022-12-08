// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./interfaces/IWeightAggregator.sol";
import "./interfaces/IBuyback.sol";
import "./interfaces/IVesting.sol";
import "./interfaces/IRewardsHub.sol";

contract WeightAggregator is IWeightAggregator {
    IBuyback public immutable buyback;
    IVesting public immutable vesting;
    IRewardsHub public immutable rewardsHub;

    constructor(
        IBuyback buyback_,
        IVesting vesting_,
        IRewardsHub rewardsHub_
    ) {
        buyback = buyback_;
        vesting = vesting_;
        rewardsHub = rewardsHub_;
    }

    /// @inheritdoc IWeightAggregator
    function getBuybackWeight(address account) external view returns (uint256) {
        if (!buyback.isParticipating(account)) return 0;
        return
            buyback.getDiscountedStake(account) +
            vesting.releasableAmount(account) +
            rewardsHub.availableBalanceOf(account);
    }

    /// @inheritdoc IWeightAggregator
    function getVotingWeight(address account) external view returns (uint256) {
        if (!buyback.isParticipating(account)) return 0;
        return
            buyback.getDiscountedStake(account) +
            vesting.getReleasableWithoutCliff(account) +
            rewardsHub.totalBalanceOf(account);
    }
}