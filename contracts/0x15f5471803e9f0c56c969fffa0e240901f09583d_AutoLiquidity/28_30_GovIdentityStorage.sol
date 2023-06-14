// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library GovIdentityStorage {

  bytes32 public constant govSlot = keccak256("GovIdentityStorage.storage.location");

  struct Identity{
    address governance;
    address rewards;
    mapping(address=>bool) strategist;
    mapping(address=>bool) admin;
  }

  function load() internal pure returns (Identity storage gov) {
    bytes32 loc = govSlot;
    assembly {
      gov.slot := loc
    }
  }
}