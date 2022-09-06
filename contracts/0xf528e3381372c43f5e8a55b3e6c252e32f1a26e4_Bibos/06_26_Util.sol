// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;
import {Test, console2} from "forge-std/Test.sol";

/// @title the bibos utility library
/// @notice utility functions
library Util {
    error NumberHasTooManyDigits();

    /// @notice wraps a string in quotes and adds a space after
    function quote(string memory value) internal pure returns (string memory) {
        return string.concat('"', value, '" ');
    }

    function keyValue(string memory _key, string memory _value) internal pure returns (string memory) {
        return string.concat('"', _key, '":"', _value, '"');
    }

    function keyValueNoQuotes(string memory _key, string memory _value) internal pure returns (string memory) {
        return string.concat('"', _key, '":', _value);
    }

    /// @notice converts a tokenId to string and pads to _digits digits
    /// @dev tokenId must be less than 10**_digits
    /// @param _tokenId, uint256, the tokenId
    /// @param _digits, uint8, the number of digits to pad to
    /// @return result the resulting string
    function uint256ToString(uint256 _tokenId, uint8 _digits) internal pure returns (string memory result) {
        uint256 max = 10**_digits;
        if (_tokenId >= max) revert NumberHasTooManyDigits();
        // add leading zeroes
        result = uint256ToString(_tokenId + max);
        assembly {
            // cut off one character
            result := add(result, 1)
            // store new length = _digits
            mstore(result, _digits)
        }
    }

    /// @notice converts a uint256 to ascii representation, without leading zeroes
    /// @param _value, uint256, the value to convert
    /// @return result the resulting string
    function uint256ToString(uint256 _value) internal pure returns (string memory result) {
        if (_value == 0) return "0";

        assembly {
            // largest uint = 2^256-1 has 78 digits
            // reserve 110 = 78 + 32 bytes of data in memory
            // (first 32 are for string length)

            // get 110 bytes of free memory
            result := add(mload(0x40), 110)
            mstore(0x40, result)

            // keep track of digits
            let digits := 0

            for {

            } gt(_value, 0) {

            } {
                // increment digits
                digits := add(digits, 1)
                // go back one byte
                result := sub(result, 1)
                // compute ascii char
                let c := add(mod(_value, 10), 48)
                // store byte
                mstore8(result, c)
                // advance to next digit
                _value := div(_value, 10)
            }
            // go back 32 bytes
            result := sub(result, 32)
            // store the length
            mstore(result, digits)
        }
    }

    function bytes1ToString(bytes1 _value) internal pure returns (string memory) {
        return uint256ToString(uint8(_value));
    }

    function uint8ToString(uint8 _value) internal pure returns (string memory) {
        return uint256ToString(_value);
    }

    /// @notice will revert in any characters are not in [0-9]
    function stringToUint256(string memory _value) internal pure returns (uint256 result) {
        // 0-9 are 48-57

        bytes memory value = bytes(_value);
        if (value.length == 0) return 0;
        uint256 multiplier = 10**(value.length - 1);
        uint256 i;
        while (multiplier != 0) {
            result += uint256((uint8(value[i]) - 48)) * multiplier;
            unchecked {
                multiplier /= 10;
                ++i;
            }
        }
    }

    function bytes1ToHex(bytes1 _value) internal pure returns (string memory) {
        bytes memory result = new bytes(2);
        uint8 x = uint8(_value);

        result[0] = getHexChar(x >> 4);
        result[1] = getHexChar(x % 16);

        return string(result);
    }

    function getHexChar(uint8 _value) internal pure returns (bytes1) {
        if (_value < 10) {
            return bytes1(_value + 48);
        }
        _value -= 10;
        return bytes1(_value + 97);
    }

    function stringToBytes1(string memory _value) internal pure returns (bytes1 result) {
        return bytes1(uint8(stringToUint256(_value)));
    }
}