//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IComplexRewarder {
	function pendingTokens(uint256 pid, address user, uint256) external returns (IERC20[] memory, uint256[] memory);
}