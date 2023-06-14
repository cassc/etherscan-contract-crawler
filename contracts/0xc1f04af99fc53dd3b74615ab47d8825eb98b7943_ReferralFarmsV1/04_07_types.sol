// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

interface ConfirmationsResolver {
  function getHead() external view returns(bytes32);
  function getConfirmation(bytes32 confirmationHash) external view returns (uint128 number, uint64 timestamp);
}