// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './INode.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStrategy is INode {
  /// @notice remove a strategy
  function remove() external;
}