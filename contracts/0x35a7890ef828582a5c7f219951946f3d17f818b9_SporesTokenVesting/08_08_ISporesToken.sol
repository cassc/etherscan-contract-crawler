// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISporesToken is IERC20 {
	/**
	 * @dev Returns the cap on the token's total supply.
	 */
	function cap() external view returns (uint256);
}