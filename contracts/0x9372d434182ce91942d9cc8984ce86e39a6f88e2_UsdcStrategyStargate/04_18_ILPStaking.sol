// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// basically a Goose MasterChef
// https://etherscan.io/address/0xB0D502E938ed5f4df2E681fE6E419ff29631d62b#code

interface ILPStaking {
	function poolInfo(uint256 _pid)
		external
		view
		returns (
			address lpToken,
			uint256 allocPoint,
			uint256 lastRewardBlock,
			uint256 accStargatePerShare
		);

	function userInfo(uint256 _pid, address _address) external view returns (uint256 amount, uint256 rewardDebt);

	function deposit(uint256 _pid, uint256 _amount) external;

	function withdraw(uint256 _pid, uint256 _amount) external;
}