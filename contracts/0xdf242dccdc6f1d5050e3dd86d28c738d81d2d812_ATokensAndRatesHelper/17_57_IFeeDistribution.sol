// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";

interface IFeeDistribution {
	struct RewardData {
		address token;
		uint256 amount;
	}

	function addReward(address rewardsToken) external;

	function removeReward(address _rewardToken) external;
}