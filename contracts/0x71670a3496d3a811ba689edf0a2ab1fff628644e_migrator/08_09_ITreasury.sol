// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ITreasury {
	function recoverERC20(address, uint256) external;
}