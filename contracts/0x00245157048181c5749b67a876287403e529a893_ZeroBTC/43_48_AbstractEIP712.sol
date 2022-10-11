// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "../utils/MemoryRestoration.sol";
import "../interfaces/EIP712Errors.sol";

bytes constant EIP712Domain_typeString = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
bytes32 constant EIP712Domain_typeHash = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

uint256 constant EIP712Signature_prefix = 0x1901000000000000000000000000000000000000000000000000000000000000;
uint256 constant EIP712Signature_domainSeparator_ptr = 0x2;
uint256 constant EIP712Signature_digest_ptr = 0x22;
uint256 constant EIP712Signature_length = 0x42;

uint256 constant DomainSeparator_nameHash_offset = 0x20;
uint256 constant DomainSeparator_versionHash_offset = 0x40;
uint256 constant DomainSeparator_chainId_offset = 0x60;
uint256 constant DomainSeparator_verifyingContract_offset = 0x80;
uint256 constant DomainSeparator_length = 0xa0;

abstract contract AbstractEIP712 is MemoryRestoration, EIP712Errors {
  uint256 private immutable _CHAIN_ID;
  bytes32 private immutable _DOMAIN_SEPARATOR;
  bytes32 private immutable _NAME_HASH;
  bytes32 private immutable _VERSION_HASH;

  constructor(string memory _name, string memory _version) {
    _CHAIN_ID = block.chainid;
    _NAME_HASH = keccak256(bytes(_name));
    _VERSION_HASH = keccak256(bytes(_version));
    _DOMAIN_SEPARATOR = _computeDomainSeparator();
    if (EIP712Domain_typeHash != keccak256(EIP712Domain_typeString)) {
      revert InvalidTypeHash();
    }
  }

  function _computeDomainSeparator() internal view returns (bytes32 separator) {
    address verifyingContract = _verifyingContract();
    bytes32 nameHash = _NAME_HASH;
    bytes32 versionHash = _VERSION_HASH;
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, EIP712Domain_typeHash)
      mstore(add(ptr, DomainSeparator_nameHash_offset), nameHash)
      mstore(add(ptr, DomainSeparator_versionHash_offset), versionHash)
      mstore(add(ptr, DomainSeparator_chainId_offset), chainid())
      mstore(
        add(ptr, DomainSeparator_verifyingContract_offset),
        verifyingContract
      )
      separator := keccak256(ptr, DomainSeparator_length)
    }
  }

  function getDomainSeparator() internal view virtual returns (bytes32) {
    return
      block.chainid == _CHAIN_ID
        ? _DOMAIN_SEPARATOR
        : _computeDomainSeparator();
  }

  function _verifyingContract() internal view virtual returns (address);
}