// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

contract RewardVaultStorage is Admin {

	address public implementation;

	struct UserInfo {
		uint256 accRewardPerB0Liquidity; // last updated accRewardPerB0Liquidity when the user triggered claim/update ops
		uint256 accRewardPerBXLiquidity; // last updated accRewardPerBXLiquidity when the user triggered claim/update ops
		uint256 unclaimed; // the unclaimed reward
		uint256 liquidityB0;
		//
		// We do some math here. Basically, any point in time, the amount of reward token
		// entitled to a user but is pending to be distributed is:
		//
		//  pending reward = lpLiquidity * (accRewardPerLiquidity - user.accRewardPerLiquidity)
		//  claimable reward = pending reward + user.unclaimed;
		//
		// Whenever a user add or remove liquidity to a pool. Here's what happens:
		//   1. The pool's `accRewardPerLiquidity` (and `lastRewardBlock`) gets updated.
		//   2. the pending reward moved to user.unclaimed.
		//   3. User's `accRewardPerLiquidity` gets updated.
	}

	// poolAddress => lTokenId => UserInfo
	mapping(address => mapping(uint256 => UserInfo)) public userInfo;

	struct VaultInfo {
		uint256 rewardPerSecond; // How many reward token per second.
		uint256 lastRewardTimestamp; // Last updated timestamp when any user triggered claim/update ops.
		uint256 accRewardPerB0Liquidity; // Accumulated reward per B0 share.
		uint256 accRewardPerBXLiquidity; // Accumulated reward per BX share.
		uint256 totalLiquidityB0;
	}

	// poolAddress => VaultInfo
	mapping(address => VaultInfo) public vaultInfo;

	// poolAddress => isAuthorized
	mapping(address => bool) public authorizedPool;

	// poolAddresses
	address[] public pools;

}