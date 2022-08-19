// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


struct Entry {

  uint256 id;

  address promotedByAddress;
  address walletAddress;

  address[] childs;

}