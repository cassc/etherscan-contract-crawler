// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMasterXFinance {
	function deposit(uint256 pid, uint256 amount) external;

	function withdraw(uint256 pid, uint256 amount) external;

	function emergencyWithdraw(uint256 pid) external;

	function userInfo(uint256 pid, address user)
		external
		view
		returns (uint256, uint256);

	function TVL(uint256 pid) external view returns (uint256);

	function APR(uint256 pid) external view returns (uint256);

	function stakedTokenPrice(uint256 _pid) external view returns (uint256);
}