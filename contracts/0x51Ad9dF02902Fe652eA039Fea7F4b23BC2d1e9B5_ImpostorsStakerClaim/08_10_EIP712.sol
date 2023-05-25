// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

abstract contract EIP712 {
  bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256 (
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  );

  struct EIP712Domain {
    string  name;
    string  version;
    uint256 chainId;
    address verifyingContract;
  }

  bytes internal personalSignPrefix = "\x19Ethereum Signed Message:\n";

  bytes32 immutable public DOMAIN_SEPARATOR;

  constructor (
    string memory _name,
    string memory _version
  ) {
    uint chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = hash(EIP712Domain({
      name: _name,
      version: _version,
      chainId: chainId,
      verifyingContract: address(this)
    }));
  }

  function hash (
    EIP712Domain memory eip712Domain
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(
      EIP712DOMAIN_TYPEHASH,
      keccak256(bytes(eip712Domain.name)),
      keccak256(bytes(eip712Domain.version)),
      eip712Domain.chainId,
      eip712Domain.verifyingContract
    ));
  }

  function parseSignature (
    bytes memory signature
  ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solhint-disable-next-line no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }
    return (v,r,s);
  }
}