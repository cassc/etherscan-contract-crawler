//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.8;

library ValueDecoder {
  function toUint(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 32))
    }
  }

  function toUint(bytes32 _bytes) internal pure returns (uint256 value) {
    assembly {
      value := _bytes
    }
  }

  function toInt(uint224 u) internal pure returns (int256) {
    int224 i;
    uint224 max = type(uint224).max;

    if (u <= (max - 1) / 2) { // positive values
      assembly {
        i := add(u, 0)
      }

      return i;
    } else { // negative values
      assembly {
        i := sub(sub(u, max), 1)
      }
    }

    return i;
  }
}