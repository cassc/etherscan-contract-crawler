// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

interface ISTokenManagerStruct {
	/*
	 * @dev Struct to declares a staking position.
	 * @param owner The address of the owner of the new staking position
	 * @param property The address of the Property as the staking destination
	 * @param amount The amount of the new staking position
	 * @param price The latest unit price of the cumulative staking reward
	 * @param cumulativeReward The cumulative withdrawn reward amount
	 * @param pendingReward The pending withdrawal reward amount amount
	 */
	struct StakingPositionV1 {
		address property;
		uint256 amount;
		uint256 price;
		uint256 cumulativeReward;
		uint256 pendingReward;
	}

	/*
	 * @dev Struct to declares staking rewards.
	 * @param entireReward The reward amount of adding the cumulative withdrawn amount
	 to the withdrawable amount
	 * @param cumulativeReward The cumulative withdrawn reward amount
	 * @param withdrawableReward The withdrawable reward amount
	 */
	struct RewardsV1 {
		uint256 entireReward;
		uint256 cumulativeReward;
		uint256 withdrawableReward;
	}
}