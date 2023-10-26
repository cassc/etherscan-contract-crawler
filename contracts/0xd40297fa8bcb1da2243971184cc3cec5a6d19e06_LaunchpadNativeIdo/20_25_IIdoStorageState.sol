// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


interface IIdoStorageState {
  enum State { None, Opened, Closed }
  enum Vesting { Short, Long }

  struct Round {
    bool defined;
    State state;
    uint256 priceVestingShort;
    uint256 priceVestingLong;
    uint256 tokensSold;
    uint256 totalSupply;
  }

  struct Referral {
    bool defined;
    bool enabled;
    uint256 mainReward;
    uint256 secondaryReward;
  }
}