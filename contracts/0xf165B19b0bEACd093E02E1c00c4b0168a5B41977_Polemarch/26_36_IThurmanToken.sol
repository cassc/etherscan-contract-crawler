// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IVotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";

interface IThurmanToken is IERC20Upgradeable, IVotesUpgradeable {

	function mint(address to, uint256 amount) external;

	function burn(address account, uint256 amount) external;
}