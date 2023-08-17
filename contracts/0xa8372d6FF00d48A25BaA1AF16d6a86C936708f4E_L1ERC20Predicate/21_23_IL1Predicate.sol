// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// LightLink 2023
interface IL1Predicate {
  /* Events */
  function l2TokenBytecodeHash() external view returns (bytes32);

  function mapToken(address _l1Token) external;
}