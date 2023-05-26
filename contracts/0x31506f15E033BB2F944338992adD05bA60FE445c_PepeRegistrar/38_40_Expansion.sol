// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../zone/Standard.sol";

contract Expansion {
  StandardZone internal zone;

  constructor(StandardZone _zone) {
    zone = _zone;
  }

  function _claimSubdomain(address to, string memory label, bytes32 projectDomain) internal returns (bytes32 namehash) {  
    return zone.register(to, projectDomain, label);
  }
}