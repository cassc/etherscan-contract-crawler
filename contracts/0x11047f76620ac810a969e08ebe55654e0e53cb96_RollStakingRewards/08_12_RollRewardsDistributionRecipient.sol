// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./RollPausable.sol";

// https://docs.synthetix.io/contracts/RewardsDistributionRecipient
abstract contract RollRewardsDistributionRecipient is RollPausable {
	address public rewardsDistribution;

	function notifyRewardAmount(
		uint256[] calldata _rewards,
		address[] calldata _tokens
	) external virtual;

	modifier onlyRewardsDistribution() {
		_onlyRewardsDistribution();
		_;
	}

	function _onlyRewardsDistribution() private view {
		require(
			msg.sender == rewardsDistribution,
			"Caller is not RewardsDistribution contract"
		);
	}

	function setRewardsDistribution(address _rewardsDistribution)
		external
		onlyOwner
	{
		require(_rewardsDistribution != address(0), "Invalid address");
		rewardsDistribution = _rewardsDistribution;
	}
}