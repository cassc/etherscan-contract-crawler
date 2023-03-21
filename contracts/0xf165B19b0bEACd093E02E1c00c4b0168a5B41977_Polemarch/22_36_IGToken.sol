// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

interface IGToken is IERC20Upgradeable {

	function mint(address caller, uint256 amount) external;

	function approvePolemarch(uint256 amount) external;

	function transferUnderlyingToExchequerSafe(uint256 amount) external;
}