// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IDelegable.sol";
import "./IERC20WithMaxTotalSupply.sol";

interface IDelegableERC20 is IDelegable, IERC20WithMaxTotalSupply {}