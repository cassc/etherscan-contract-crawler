// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

interface ISToken is IERC20Upgradeable, IScaledBalanceToken {

	function mint(address account, uint256 amount, uint256 index) external;

	function burn(address account, uint256 amount, uint256 index) external;

	function transferUnderlying(address to, uint256 amount) external;

	function transferUnderlyingToExchequerSafe(uint256 amount) external;

	function withdrawableBalance(
		address user,
		uint256 totalDebt
	) external returns (uint256);

}