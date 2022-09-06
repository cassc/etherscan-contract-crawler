pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import { MemcpyLib } from "./MemcpyLib.sol";

library SliceLib {
  struct Slice {
    uint256 data;
    uint256 length;
    uint256 offset;
  }

  function toPtr(bytes memory input, uint256 offset) internal pure returns (uint256 data) {
    assembly {
      data := add(input, add(offset, 0x20))
    }
  }

  function toSlice(
    bytes memory input,
    uint256 offset,
    uint256 length
  ) internal pure returns (Slice memory retval) {
    retval.data = toPtr(input, offset);
    retval.length = length;
    retval.offset = offset;
  }

  function toSlice(bytes memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }

  function toSlice(bytes memory input, uint256 offset) internal pure returns (Slice memory) {
    if (input.length < offset) offset = input.length;
    return toSlice(input, offset, input.length - offset);
  }

  function toSlice(
    Slice memory input,
    uint256 offset,
    uint256 length
  ) internal pure returns (Slice memory) {
    return Slice({ data: input.data + offset, offset: input.offset + offset, length: length });
  }

  function toSlice(Slice memory input, uint256 offset) internal pure returns (Slice memory) {
    return toSlice(input, offset, input.length - offset);
  }

  function toSlice(Slice memory input) internal pure returns (Slice memory) {
    return toSlice(input, 0);
  }

  function maskLastByteOfWordAt(uint256 data) internal pure returns (uint8 lastByte) {
    assembly {
      lastByte := and(mload(data), 0xff)
    }
  }

  function get(Slice memory slice, uint256 index) internal pure returns (bytes1 result) {
    return bytes1(maskLastByteOfWordAt(slice.data - 0x1f + index));
  }

  function setByteAt(uint256 ptr, uint8 value) internal pure {
    assembly {
      mstore8(ptr, value)
    }
  }

  function set(
    Slice memory slice,
    uint256 index,
    uint8 value
  ) internal pure {
    setByteAt(slice.data + index, value);
  }

  function wordAt(uint256 ptr, uint256 length) internal pure returns (bytes32 word) {
    assembly {
      let mask := sub(shl(mul(length, 0x8), 0x1), 0x1)
      word := and(mload(sub(ptr, sub(0x20, length))), mask)
    }
  }

  function asWord(Slice memory slice) internal pure returns (bytes32 word) {
    uint256 data = slice.data;
    uint256 length = slice.length;
    return wordAt(data, length);
  }

  function toDataStart(bytes memory input) internal pure returns (bytes32 start) {
    assembly {
      start := add(input, 0x20)
    }
  }

  function copy(Slice memory slice) internal pure returns (bytes memory retval) {
    uint256 length = slice.length;
    retval = new bytes(length);
    bytes32 src = bytes32(slice.data);
    bytes32 dest = toDataStart(retval);
    MemcpyLib.memcpy(dest, src, length);
  }

  function keccakAt(uint256 data, uint256 length) internal pure returns (bytes32 result) {
    assembly {
      result := keccak256(data, length)
    }
  }

  function toKeccak(Slice memory slice) internal pure returns (bytes32 result) {
    return keccakAt(slice.data, slice.length);
  }
}