// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingRewards {
	struct UserInfo {
		uint256 amount; // How many LP tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
	}

	// Info of each pool.
	struct PoolInfo {
		IERC20 lpToken; // Address of LP token contract.
		uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
		uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
		uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
	}

	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event XFTRewardPaid(address indexed user, uint256 reward);
	event SUSHIRewardPaid(address indexed user, uint256 reward);

	function totalStaked() external view returns (uint256);

	function balanceOf(address _account) external view returns (uint256);

	function getRewardForDuration() external view returns (uint256);

	function lastTimeRewardApplicable() external view returns (uint256);

	function rewardPerToken() external view returns (uint256);

	function earnedXFT(address _account) external view returns (uint256);

	function earnedSushi(address _account) external view returns (uint256);

	function stake(uint256 _amount) external;

	function withdraw(uint256 _amount) external;

	function getReward() external;

	function exit() external;
}