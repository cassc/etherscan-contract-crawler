// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

contract CollabStorage {
  // user address => ( activity string id => ipfs url string)
  mapping(address => mapping(string => string)) internal _stamp;

  //
  mapping(string => bool) internal _protectedActivities;

  // whether an address is an signer
  mapping(address => bool) internal _signers;

  string[47] _gap;
}