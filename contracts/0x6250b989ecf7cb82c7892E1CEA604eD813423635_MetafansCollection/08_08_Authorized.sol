// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Authorized {
  bytes32 internal immutable _domainSeparator;

  address internal _authority;

  constructor() {
    bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    _domainSeparator = keccak256(
      abi.encode(typeHash, keccak256(bytes("MetaFans")), keccak256(bytes("1.0.0")), block.chainid, address(this))
    );
  }

  modifier authorized(
    address account,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) {
    bytes32 hash = keccak256(abi.encode(keccak256("Presale(address to,uint256 deadline)"), account, deadline));

    require(verify(hash, v, r, s), "unauthorized");

    _;
  }

  function verify(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal view returns (bool) {
    return _authority == ecrecover(keccak256(abi.encodePacked("\x19\x01", _domainSeparator, hash)), v, r, s);
  }
}