// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library ECDSA {
  error InvalidSignature();

  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    if (signature.length != 65) {
      revert InvalidSignature();
    }
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }
    return tryRecover(hash, v, r, s);
  }

  function tryRecover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address) {
    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      revert InvalidSignature();
    }
    return ecrecover(hash, v, r, s);
  }
}