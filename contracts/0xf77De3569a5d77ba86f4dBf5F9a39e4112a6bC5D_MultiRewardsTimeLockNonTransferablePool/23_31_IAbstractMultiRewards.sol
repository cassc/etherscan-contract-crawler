// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAbstractMultiRewards {
	/**
	 * @dev Returns the total amount of rewards a given address is able to withdraw.
	 * @param reward Address of the reward token
	 * @param account Address of a reward recipient
	 * @return A uint256 representing the rewards `account` can withdraw
	 */
	function withdrawableRewardsOf(address reward, address account) external view returns (uint256);

  /**
	 * @dev View the amount of funds that an address has withdrawn.
	 * @param reward The address of the reward token.
	 * @param account The address of a token holder.
	 * @return The amount of funds that `account` has withdrawn.
	 */
	function withdrawnRewardsOf(address reward, address account) external view returns (uint256);

	/**
	 * @dev View the amount of funds that an address has earned in total.
	 * accumulativeFundsOf(reward, account) = withdrawableRewardsOf(reward, account) + withdrawnRewardsOf(reward, account)
	 * = (pointsPerShare * balanceOf(account) + pointsCorrection[reward][account]) / POINTS_MULTIPLIER
	 * @param reward The address of the reward token.
	 * @param account The address of a token holder.
	 * @return The amount of funds that `account` has earned in total.
	 */
	function cumulativeRewardsOf(address reward, address account) external view returns (uint256);

	/**
	 * @dev This event emits when new funds are distributed
	 * @param by the address of the sender who distributed funds
	 * @param reward the address of the reward token
	 * @param rewardsDistributed the amount of funds received for distribution
	 */
	event RewardsDistributed(address indexed by, address indexed reward, uint256 rewardsDistributed);

	/**
	 * @dev This event emits when distributed funds are withdrawn by a token holder.
	 * @param reward the address of the reward token
	 * @param by the address of the receiver of funds
	 * @param fundsWithdrawn the amount of funds that were withdrawn
	 */
	event RewardsWithdrawn(address indexed reward, address indexed by, uint256 fundsWithdrawn);
}