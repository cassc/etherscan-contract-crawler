// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IUSTPHelper {
	function wraprUSTPToUSTP(uint256 amount) external returns (uint256);

	function wrapiUSTPToUSTP(uint256 amount) external returns (uint256);
}