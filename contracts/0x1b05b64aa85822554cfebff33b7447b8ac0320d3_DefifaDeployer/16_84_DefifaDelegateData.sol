// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-721-delegate/contracts/structs/JB721TierParams.sol';
import '@jbx-protocol/juice-721-delegate/contracts/interfaces/IJBTiered721DelegateStore.sol';

/**
  @member name The name of the token.
  @member symbol The symbol that the token should be represented by.
  @member baseUri A URI to use as a base for full token URIs.
  @member contractUri A URI where contract metadata can be found. 
  @member tiers The tiers to set.
  @member store The store contract to use.
  @member owner The address that should own the delegate contract.
*/
struct DefifaDelegateData {
  string name;
  string symbol;
  string baseUri;
  string contractUri;
  JB721TierParams[] tiers;
  IJBTiered721DelegateStore store;
  address owner;
}