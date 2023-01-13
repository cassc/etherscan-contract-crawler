// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IComplexRewarder.sol";

struct UserInfo {
	uint256 amount;
	int256 rewardDebt;
}

struct PoolInfo {
	uint128 accSushiPerShare;
	uint64 lastRewardBlock;
	uint64 allocPoint;
}

/// @title Interface for the SushiSwap MasterChef V2 contract
interface IMasterChefV2 {
	function deposit(uint256 pid, uint256 amount, address to) external;

	function withdraw(uint256 pid, uint256 amount, address to) external;

	function userInfo(uint256 pid, address user) external returns (uint256, uint256);

	function harvest(uint256 pid, address to) external;

	// solhint-disable-next-line func-name-mixedcase
	function SUSHI() external returns (IERC20);

	function rewarder(uint256 pid) external returns (IComplexRewarder);

	function lpToken(uint256 pid) external returns (IERC20);

	function pendingSushi(uint256 pid, address user) external returns (uint256);
}