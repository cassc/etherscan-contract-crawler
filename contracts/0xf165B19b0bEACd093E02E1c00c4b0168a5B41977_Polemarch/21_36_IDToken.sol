// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IDToken is IERC20Upgradeable {

	event Mint(
		address indexed user,
		uint256 currentBalance,
		uint256 balanceIncrease,
		uint256 amount
	);

	event Burn(
		address indexed user,
		uint256 currentBalance,
		uint256 balanceIncrease,
		uint256 amount
	);

	function mint(address user, uint256 amount) external;

	function burn(address user, uint256 amount) external;

	function updateRate(address user, uint128 rate) external;

	function userRate(address user) external returns (uint128);

	function getAverageRate() external returns (uint256);

	// function borrowBalance(address user) external;
}