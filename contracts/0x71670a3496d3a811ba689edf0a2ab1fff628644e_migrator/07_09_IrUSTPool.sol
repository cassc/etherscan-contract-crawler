// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IrUSTPool {
	function migrate(address _user, address _borrower, uint256 _amount) external;

	function supplyUSDC(uint256 _amount) external;
}