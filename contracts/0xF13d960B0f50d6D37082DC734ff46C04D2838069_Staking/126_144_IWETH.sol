// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 *  @title Interface for the WETH token
 */
interface IWETH is IERC20Upgradeable {
	event Deposit(address, uint256);
	event Withdrawal(address, uint256);

	function deposit() external payable;

	function withdraw(uint256) external;
}