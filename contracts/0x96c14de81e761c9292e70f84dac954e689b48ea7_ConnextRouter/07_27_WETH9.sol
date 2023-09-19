// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IWETH9
 *
 * @author Unknown
 *
 * @notice Abstract contract of add-on functions of a
 * typical ERC20 wrapped native token.
 */

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

abstract contract IWETH9 is ERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable virtual;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external virtual;
}