// SPDX-License-Identifier: MIT

// 1795284 gas

pragma solidity ^0.8.0;


import "./AddressTree2HEADER.sol";


struct Calcs {
    uint256 start;
    uint256 end;
    uint256 volume;
}

struct Digs {
    uint256 timestamp;
    uint256 units;

    uint sIndex;

    address currency;
    uint256 price;
    uint256 decimals;
}

struct Rocking {
    address currency;
    uint256 price;
    uint256 decimals;

    uint256 apy;
    uint256 from;
    uint256 till;
    uint256 limit;
}


struct RockEntryLight {
  address delegatePaymentToAddress;

  uint[ 25 ] b;
  uint dCount;
  uint cCount;

}

struct RockEntry {
  address delegatePaymentToAddress;

  uint[ 25 ] b;
  uint dCount;
  uint cCount;

  mapping(uint => Digs) d;
  mapping(uint => Calcs) c;
  mapping(address => uint256) allowances;
  mapping(address => uint256) allowancesTime;
  mapping(uint256 => uint256) deadStore;

}