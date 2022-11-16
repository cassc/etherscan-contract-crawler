// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://docs.convexfinance.com/convexfinanceintegration/baserewardpool
// https://github.com/convex-eth/platform/blob/main/contracts/contracts/BaseRewardPool.sol

interface IBaseRewardPool {
	function balanceOf(address _account) external view returns (uint256);

	function getReward(address _account, bool _claimExtras) external returns (bool);

	function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}