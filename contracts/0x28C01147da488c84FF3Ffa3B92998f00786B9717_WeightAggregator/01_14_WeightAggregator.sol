// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./interfaces/IWeightAggregator.sol";
import "./interfaces/IBuyback.sol";
import "./interfaces/IVesting.sol";
import "./interfaces/IRewardsHub.sol";

contract WeightAggregator is IWeightAggregator {
    uint256 internal constant LOYALTY_SCALE = 1e18;

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
    function getAccountFunds(address account) public view returns (uint256) {
        return
            buyback.getStakedAmount(account) +
            vesting.releasableAmount(account) +
            rewardsHub.availableBalanceOf(account);
    }

    function getLoyaltyFactor(address account) external view returns (uint256) {
        return buyback.getLoyaltyFactorForBalance(account, getAccountFunds(account));
    }

    /// @inheritdoc IWeightAggregator
    function getBuybackWeight(address account) external view returns (uint256) {
        if (!buyback.isParticipating(account)) return 0;

        uint256 funds = getAccountFunds(account);
        uint256 loyaltyFactor = buyback.getLoyaltyFactorForBalance(account, funds);
        return funds + (funds * loyaltyFactor) / LOYALTY_SCALE;
    }

    /// @inheritdoc IWeightAggregator
    function getVotingWeight(address account) external view returns (uint256) {
        if (!buyback.isParticipating(account)) return 0;

        uint256 funds = getAccountFunds(account);
        uint256 loyaltyFactor = buyback.getLoyaltyFactorForBalance(account, funds);

        uint256 votes = buyback.getStakedAmount(account) +
            vesting.getReleasableWithoutCliff(account) +
            rewardsHub.totalBalanceOf(account);
        return votes + (votes * loyaltyFactor) / LOYALTY_SCALE;
    }
}