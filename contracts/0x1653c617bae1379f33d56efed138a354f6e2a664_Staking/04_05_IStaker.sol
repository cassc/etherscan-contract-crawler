// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface IStaker {
	function increaseDepositNb() external;
	function decreaseDepositNb() external;
	function pending(address) external view returns (uint);
	function distribute() external;
	function withdraw(address, uint) external;
}