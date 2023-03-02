// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library SplitSignatureLib {
  function splitSignature(bytes memory sig)
    internal
    pure
    returns (
      uint8 v,
      bytes32 r,
      bytes32 s
    )
  {
    require(sig.length == 65);
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
    return (v, r, s);
  }
}