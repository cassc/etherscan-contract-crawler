// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

/*
 * Website: alacritylsd.com
 * X/Twitter: x.com/alacritylsd
 * Telegram: t.me/alacritylsd
 */

abstract contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    function notifyRewardAmount(uint256 reward) external virtual;
}