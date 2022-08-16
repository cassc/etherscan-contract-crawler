// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

/**
@title must be inherited by a contract that will be deployed with ZeroFactoryLib
@author raymondpulver
*/
abstract contract Implementation {
  /**
  @notice ensure the contract cannot be initialized twice
  */
  function lock() public virtual {
    // no other logic
  }
}