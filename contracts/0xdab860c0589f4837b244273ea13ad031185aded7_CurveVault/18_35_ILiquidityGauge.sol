// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface ILiquidityGauge {
	struct Reward {
		address token;
		address distributor;
		uint256 period_finish;
		uint256 rate;
		uint256 last_update;
		uint256 integral;
	}

	// solhint-disable-next-line
	function deposit_reward_token(address _rewardToken, uint256 _amount) external;

	// solhint-disable-next-line
	function claim_rewards_for(address _user, address _recipient) external;

	// // solhint-disable-next-line
	// function claim_rewards_for(address _user) external;

	// solhint-disable-next-line
	function deposit(uint256 _value, address _addr) external;

	// solhint-disable-next-line
	function reward_tokens(uint256 _i) external view returns (address);

	// solhint-disable-next-line
	function reward_data(address _tokenReward) external view returns (Reward memory);

	function balanceOf(address) external returns (uint256);

	function claimable_reward(address _user, address _reward_token) external view returns (uint256);

	function claimable_tokens(address _user) external returns (uint256);

	function user_checkpoint(address _user) external returns (bool);

	function commit_transfer_ownership(address) external;

	function claim_rewards(address) external;

	function add_reward(address, address) external;

	function initialize(
		address staking_token,
		address admin,
		address SDT,
		address voting_escrow,
		address veBoost_proxy,
		address distributor
	) external;
}