// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Generatable
 * @author artpumpkin
 * @notice Generates a unique id
 */
contract Generatable {
  uint256 private _id;

  /**
   * @notice Generates a unique id
   * @return id The newly generated id
   */
  function unique() internal returns (uint256) {
    _id += 1;
    return _id;
  }
}