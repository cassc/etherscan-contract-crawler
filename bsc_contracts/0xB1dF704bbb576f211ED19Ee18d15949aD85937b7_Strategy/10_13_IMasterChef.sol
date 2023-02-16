// SPDX-License-Identifier: BUSL-1.1

import { IERC20 } from "./IERC20.sol";

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct UserInfo {
	uint256 amount; // How many LP tokens the user has provided.
	uint256 rewardDebt; // Reward debt. See explanation below.
}

struct PoolInfo {
	IERC20 lpToken; // Address of LP token contract.
	uint256 allocPoint; // How many allocation points assigned to this pool. STGs to distribute per block.
	uint256 lastRewardBlock; // Last block number that STGs distribution occurs.
	uint256 accStargatePerShare; // Accumulated STGs per share, times 1e12. See below.
}

interface IMasterChef {
	function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

	function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

	function pendingStargate(uint256 _pid, address _user) external view returns (uint256);

	function deposit(uint256 _pid, uint256 _amount) external;

	function withdraw(uint256 _pid, uint256 _amount) external;

	function emergencyWithdraw(uint256 _pid) external;
}