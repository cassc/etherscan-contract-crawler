// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ICompounder {
	function claimCompound(address _user, bool _execute, uint256 _slippage) external returns (uint256 tokensOut);

	function viewPendingRewards(address user) external view returns (address[] memory tokens, uint256[] memory amts);

	function estimateReturns(address _in, address _out, uint256 amtIn) external view returns (uint256 amtOut);
}