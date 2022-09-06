// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

// Rights Status information
struct RightsStatus { 
  address authority;
  address operator;
  address partner;
  uint256 authorityDate;
  uint256 frozenDate;
}

// Diamond AppStorage
struct AppStorage {
  Counters.Counter _id;
  bool _useAllowlist; 
  mapping(address => bool) _allowlist; // List of addresses that can make declarations using this contract
  mapping(uint256 => string) _rights; // Maps Rights ID to Rights URI
  mapping(address => mapping(uint256 => uint256[])) _ids; // Maps NFT (Smart Contract address / Token ID) to the list of Rights IDs
  mapping(address => RightsStatus) _contractStatus; // Maps NFT Smart Contract address to Rights Status information (contract-level)
  mapping(address => mapping(uint256 => RightsStatus)) _tokenStatus; // Maps NFT (Smart Contract address / Token ID) to Rights Status information (token-level)
}