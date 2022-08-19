// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


struct Entry {

  uint256 id;

  //mapping list of users who ever staked

  address promotedByAddress;
  address walletAddress;

  // will be pushed
  address[] childs;

}