// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

abstract contract ENSReverseRegistrar {
  function setName(string memory name) public virtual returns (bytes32);
}