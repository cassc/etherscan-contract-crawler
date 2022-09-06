// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

library SplitSignatureLib {
  function splitSignature(bytes memory signature)
    internal
    pure
    returns (
      uint8 v,
      bytes32 r,
      bytes32 s
    )
  {
    if (signature.length == 65) {
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
    } else if (signature.length == 64) {
      assembly {
        r := mload(add(signature, 0x20))
        let vs := mload(add(signature, 0x40))
        s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
        v := add(shr(255, vs), 27)
      }
    }
  }
}