// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterChef {
	function poolInfo(uint256)
		external
		view
		returns (
			address lpToken,
			uint256 allocPoint,
			uint256 lastRewardBlock,
			uint256 accSushiPerShare
		);

	function userInfo(uint256, address)
		external
		view
		returns (uint256 amount, uint256 rewardDebt);

	function deposit(uint256 _pid, uint256 _amount) external;

	function withdraw(uint256 _pid, uint256 _amount) external;

	function updatePool(uint256 _pid) external;

	function getMultiplier(uint256 _from, uint256 _to)
		external
		view
		returns (uint256);

	function sushiPerBlock() external view returns (uint256);

	function totalAllocPoint() external view returns (uint256);
}