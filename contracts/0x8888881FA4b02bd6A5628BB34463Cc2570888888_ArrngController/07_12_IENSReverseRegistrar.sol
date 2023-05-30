// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// Included to allow setting of ENS reverse register for contract:
interface IENSReverseRegistrar {
  function setName(string memory name) external returns (bytes32);
}