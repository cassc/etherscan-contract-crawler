// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IReservoirOracle {
  struct Message {
    bytes32 id;
    bytes payload;
    uint256 timestamp;
    bytes signature;
  }

  function verifyMessage(bytes32 id, uint256 validFor, Message memory message) external view returns (bool success);
}