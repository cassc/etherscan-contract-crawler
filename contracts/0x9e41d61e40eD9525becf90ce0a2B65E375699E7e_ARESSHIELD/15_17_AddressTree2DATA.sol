// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AddressTree2HEADER.sol";



abstract contract AddressTree2DATA {

  // database
  mapping(address => Entry) m;

  // database entry helper
  mapping(address => bool) mExists;

  // reverse lookup
  mapping(address => address) mPromotedBy;

  //array of all stakers
  address[] _mAddress;



  bool simpleMode = false;

  uint256 globalMemberId = 0;



  uint8 _maxDepth = 6;

  uint8 _balanceMax = 20;

  uint8 public max = 17;


  constructor() {

    address promotedByAddress = address(0);

    mExists[ promotedByAddress ] = true;
  }

}