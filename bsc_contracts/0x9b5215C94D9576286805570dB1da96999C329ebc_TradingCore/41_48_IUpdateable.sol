// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IUpdateable {
  struct Updateable {
    uint256 current;
    uint256 uptoLastUpdate;
    uint32 lastUpdate;
    uint32 initialUpdate;
  }

  struct SignedUpdateable {
    int256 current;
    int256 uptoLastUpdate;
    uint32 lastUpdate;
    uint32 initialUpdate;
  }
}