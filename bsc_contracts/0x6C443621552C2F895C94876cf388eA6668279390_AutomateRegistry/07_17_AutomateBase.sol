// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AutomateBase {
  error OnlyForCalling();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function doNotExecute() internal view {
    if (tx.origin != address(0)) {
      revert OnlyForCalling();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier notExecute() {
    doNotExecute();
    _;
  }
}