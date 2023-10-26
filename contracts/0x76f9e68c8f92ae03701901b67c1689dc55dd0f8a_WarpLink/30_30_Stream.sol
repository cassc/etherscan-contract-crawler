// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * Stream reader
 *
 * Note that the stream position is always behind by one as per the
 * original implementation
 *
 * See https://github.com/sushiswap/sushiswap/blob/master/protocols/route-processor/contracts/InputStream.sol
 */
library Stream {
  function createStream(bytes memory data) internal pure returns (uint256 stream) {
    assembly {
      // Get a pointer to the next free memory
      stream := mload(0x40)

      // Move the free memory pointer forward by 64 bytes, since
      // this function will store 2 words (64 bytes) to memory.
      mstore(0x40, add(stream, 64))

      // Store a pointer to the data in the first word of the stream
      mstore(stream, data)

      // Store a pointer to the end of the data in the second word of the stream
      let length := mload(data)
      mstore(add(stream, 32), add(data, length))
    }
  }

  function isNotEmpty(uint256 stream) internal pure returns (bool) {
    uint256 pos;
    uint256 finish;
    assembly {
      pos := mload(stream)
      finish := mload(add(stream, 32))
    }
    return pos < finish;
  }

  function readUint8(uint256 stream) internal pure returns (uint8 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 1)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint16(uint256 stream) internal pure returns (uint16 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 2)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint24(uint256 stream) internal pure returns (uint24 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 3)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint32(uint256 stream) internal pure returns (uint32 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 4)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint48(uint256 stream) internal pure returns (uint48 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 6)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint160(uint256 stream) internal pure returns (uint160 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 20)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint256(uint256 stream) internal pure returns (uint256 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 32)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readBytes32(uint256 stream) internal pure returns (bytes32 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 32)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readAddress(uint256 stream) internal pure returns (address res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 20)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readBytes(uint256 stream) internal pure returns (bytes memory res) {
    assembly {
      let pos := mload(stream)
      res := add(pos, 32)
      let length := mload(res)
      mstore(stream, add(res, length))
    }
  }

  function readAddresses(
    uint256 stream,
    uint256 count
  ) internal pure returns (address[] memory res) {
    res = new address[](count);

    for (uint256 index; index < count; ) {
      res[index] = readAddress(stream);

      unchecked {
        index++;
      }
    }
  }

  function readUint16s(uint256 stream, uint256 count) internal pure returns (uint16[] memory res) {
    res = new uint16[](count);

    for (uint256 index; index < count; ) {
      res[index] = readUint16(stream);

      unchecked {
        index++;
      }
    }
  }
}