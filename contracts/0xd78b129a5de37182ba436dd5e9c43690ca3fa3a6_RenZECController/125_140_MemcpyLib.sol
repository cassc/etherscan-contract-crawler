pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library MemcpyLib {
  function memcpy(
    bytes32 dest,
    bytes32 src,
    uint256 len
  ) internal pure {
    assembly {
      for {

      } iszero(lt(len, 0x20)) {
        len := sub(len, 0x20)
      } {
        mstore(dest, mload(src))
        dest := add(dest, 0x20)
        src := add(src, 0x20)
      }
      let mask := sub(shl(mul(sub(32, len), 8), 1), 1)
      mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
    }
  }
}