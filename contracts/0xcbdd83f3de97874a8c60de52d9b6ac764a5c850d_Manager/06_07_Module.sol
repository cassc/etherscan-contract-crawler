// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/// Wraps Federation module functionality
interface Module {
  /// init is called when a new module is enabled from a base wallet
  function init(bytes calldata) external payable;
}