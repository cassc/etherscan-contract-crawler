// SPDX-License-Identifier: MIT
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/260e082/contracts/utils/ShortStrings.sol
// TODO: Swap out for the OZ library version once this has been published.

pragma solidity ^0.8.18;

type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 * Strings of arbitrary length can be optimized if they are short enough by
 * the addition of a storage variable used as fallback.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
  error StringTooLong(string str);

  /**
   * @dev Encode a string of at most 31 chars into a `ShortString`.
   *
   * This will trigger a `StringTooLong` error is the input string is too long.
   */
  function toShortString(string memory str) internal pure returns (ShortString) {
    bytes memory bstr = bytes(str);
    if (bstr.length > 31) {
      revert StringTooLong(str);
    }
    return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
  }

  /**
   * @dev Decode a `ShortString` back to a "normal" string.
   */
  function toString(ShortString sstr) internal pure returns (string memory) {
    uint256 len = length(sstr);
    // using `new string(len)` would work locally but is not memory safe.
    string memory str = new string(32);
    /// @solidity memory-safe-assembly
    assembly {
      mstore(str, len)
      mstore(add(str, 0x20), sstr)
    }
    return str;
  }

  /**
   * @dev Return the length of a `ShortString`.
   */
  function length(ShortString sstr) internal pure returns (uint256) {
    return uint256(ShortString.unwrap(sstr)) & 0xFF;
  }
}