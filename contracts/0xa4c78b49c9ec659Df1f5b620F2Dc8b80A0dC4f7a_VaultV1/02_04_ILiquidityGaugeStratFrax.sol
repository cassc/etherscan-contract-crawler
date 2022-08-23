// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface ILiquidityGaugeStratFrax {
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

	function claim_rewards(address _addr, address _recipient) external;

	// solhint-disable-next-line
	function claim_rewards_for(address _user, address _recipient) external;

	// // solhint-disable-next-line
	// function claim_rewards_for(address _user) external;

	// solhint-disable-next-line
	function deposit(
		uint256 _value,
		address _addr,
		bool _claim_reward
	) external;

	// solhint-disable-next-line
	function reward_tokens(uint256 _i) external view returns (address);

	function reward_count() external view returns (uint256);

	function initialized() external view returns (bool);

	function withdraw(
		uint256 _value,
		address _addr,
		bool _claim_rewards
	) external;

	// solhint-disable-next-line
	function reward_data(address _tokenReward) external view returns (Reward memory);

	function balanceOf(address) external returns (uint256);

	function claimable_reward(address _user, address _reward_token) external view returns (uint256);

	function user_checkpoint(address _user) external returns (bool);

	function commit_transfer_ownership(address) external;

	function initialize(
		address _admin,
		address _SDT,
		address _voting_escrow,
		address _veBoost_proxy,
		address _distributor,
		uint256 _pid,
		address _poolRegistry
	) external;

	function add_reward(address, address) external;
}