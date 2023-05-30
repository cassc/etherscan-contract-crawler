//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library utils {
  function getColorName(uint256 _hue) public pure returns (string memory) {
    string[12] memory colorNames = [
      "Red",
      "Orange",
      "Yellow",
      "Chartreuse",
      "Green",
      "Spring",
      "Cyan",
      "Azure",
      "Blue",
      "Violet",
      "Magenta",
      "Rose"
    ];

    require(_hue <= 360, "Hue must be between 0 and 360");

    uint256 colorIndex = (_hue * 12) / 360;
    return colorNames[colorIndex];
  }

  function getHSL(uint256 hue, uint256 saturation, uint256 lightness) internal pure returns (string memory) {
    return
      string.concat(
        "hsl(",
        utils.uint2str(hue),
        ", ",
        utils.uint2str(saturation),
        "%, ",
        utils.uint2str(lightness),
        "%)"
      );
  }

  function assemblyKeccak(bytes memory _input) public pure returns (bytes32 x) {
    assembly {
      x := keccak256(add(_input, 0x20), mload(_input))
    }
  }

  function random(string memory input) internal pure returns (uint256) {
    return uint256(assemblyKeccak(abi.encodePacked(input)));
  }

  function randomRange(
    uint256 tokenId,
    string memory keyPrefix,
    uint256 lower,
    uint256 upper
  ) internal pure returns (uint256) {
    uint256 rand = random(string(abi.encodePacked(keyPrefix, uint2str(tokenId))));
    return (rand % (upper - lower + 1)) + lower;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
    require(bs.length >= start + 32, "slicing out of range");
    uint256 x;
    assembly {
      x := mload(add(bs, add(0x20, start)))
    }
    return x;
  }

  function int2str(int256 _i) internal pure returns (string memory _uintAsString) {
    if (_i < 0) {
      return string.concat("-", uint2str(uint256(-_i)));
    } else {
      return uint2str(uint256(_i));
    }
  }

  function uint2floatstr(uint256 _i_scaled, uint256 _decimals) internal pure returns (string memory) {
    return string.concat(uint2str(_i_scaled / (10 ** _decimals)), ".", uint2str(_i_scaled % (10 ** _decimals)));
  }

  // converts an unsigned integer to a string from Solady (https://github.com/vectorized/solady/blob/main/src)
  /// @dev Returns the base 10 decimal representation of `value`.
  function uint2str(uint256 value) internal pure returns (string memory str) {
    /// @solidity memory-safe-assembly
    assembly {
      // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
      // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
      // We will need 1 word for the trailing zeros padding, 1 word for the length,
      // and 3 words for a maximum of 78 digits.
      str := add(mload(0x40), 0x80)
      // Update the free memory pointer to allocate.
      mstore(0x40, add(str, 0x20))
      // Zeroize the slot after the string.
      mstore(str, 0)

      // Cache the end of the memory to calculate the length later.
      let end := str

      let w := not(0) // Tsk.
      // We write the string from rightmost digit to leftmost digit.
      // The following is essentially a do-while loop that also handles the zero case.
      for {
        let temp := value
      } 1 {

      } {
        str := add(str, w) // `sub(str, 1)`.
        // Write the character to the pointer.
        // The ASCII index of the '0' character is 48.
        mstore8(str, add(48, mod(temp, 10)))
        // Keep dividing `temp` until zero.
        temp := div(temp, 10)
        if iszero(temp) {
          break
        }
      }

      let length := sub(end, str)
      // Move the pointer 32 bytes leftwards to make room for the length.
      str := sub(str, 0x20)
      // Store the length.
      mstore(str, length)
    }
  }

  /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
  /// See: https://datatracker.ietf.org/doc/html/rfc4648
  /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
  /// @param noPadding Whether to strip away the padding.
  function encode(bytes memory data, bool fileSafe, bool noPadding) internal pure returns (string memory result) {
    /// @solidity memory-safe-assembly
    assembly {
      let dataLength := mload(data)

      if dataLength {
        // Multiply by 4/3 rounded up.
        // The `shl(2, ...)` is equivalent to multiplying by 4.
        let encodedLength := shl(2, div(add(dataLength, 2), 3))

        // Set `result` to point to the start of the free memory.
        result := mload(0x40)

        // Store the table into the scratch space.
        // Offsetted by -1 byte so that the `mload` will load the character.
        // We will rewrite the free memory pointer at `0x40` later with
        // the allocated size.
        // The magic constant 0x0230 will translate "-_" + "+/".
        mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
        mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

        // Skip the first slot, which stores the length.
        let ptr := add(result, 0x20)
        let end := add(ptr, encodedLength)

        // Run over the input, 3 bytes at a time.
        for {

        } 1 {

        } {
          data := add(data, 3) // Advance 3 bytes.
          let input := mload(data)

          // Write 4 bytes. Optimized for fewer stack operations.
          mstore8(0, mload(and(shr(18, input), 0x3F)))
          mstore8(1, mload(and(shr(12, input), 0x3F)))
          mstore8(2, mload(and(shr(6, input), 0x3F)))
          mstore8(3, mload(and(input, 0x3F)))
          mstore(ptr, mload(0x00))

          ptr := add(ptr, 4) // Advance 4 bytes.

          if iszero(lt(ptr, end)) {
            break
          }
        }

        // Allocate the memory for the string.
        // Add 31 and mask with `not(31)` to round the
        // free memory pointer up the next multiple of 32.
        mstore(0x40, and(add(end, 31), not(31)))

        // Equivalent to `o = [0, 2, 1][dataLength % 3]`.
        let o := div(2, mod(dataLength, 3))

        // Offset `ptr` and pad with '='. We can simply write over the end.
        mstore(sub(ptr, o), shl(240, 0x3d3d))
        // Set `o` to zero if there is padding.
        o := mul(iszero(iszero(noPadding)), o)
        // Zeroize the slot after the string.
        mstore(sub(ptr, o), 0)
        // Write the length of the string.
        mstore(result, sub(encodedLength, o))
      }
    }
  }

  /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
  /// Equivalent to `encode(data, false, false)`.
  function encode(bytes memory data) internal pure returns (string memory result) {
    result = encode(data, false, false);
  }
}