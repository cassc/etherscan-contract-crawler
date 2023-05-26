// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../zone/Standard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Expansion.sol";

contract Signable is Expansion {
  using ECDSA for bytes32;

  constructor(StandardZone _zone)
    Expansion(
      _zone
    ) 
  {}
  
  function delegate(address to, bytes32 projectDomain) public pure returns (bytes32) {
    return keccak256(abi.encode(to, projectDomain));
  }

  function delegateHash(address to, bytes32 projectDomain) public pure returns (bytes32) {
    return delegate(to, projectDomain).toEthSignedMessageHash();
  }

  function validateSignature(
    address to,
    bytes memory ownerSignature, bytes32 projectDomain
  ) public view returns (bool) {
    address _owner = delegateHash(to, projectDomain).recover(ownerSignature);
    return _owner == zone.ownerOf(uint256(projectDomain));
  }
}