//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// @title the storage of StakeQuoterStorage
contract StakeQuoterStorage {
    address public quoter;
    int24 public changeTick;
    int24 public acceptTickIntervalInOracle;
}