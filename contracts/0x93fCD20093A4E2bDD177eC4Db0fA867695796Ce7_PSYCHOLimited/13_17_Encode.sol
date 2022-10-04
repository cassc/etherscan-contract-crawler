// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "./Log.sol";

library Encode {
    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toBase64(bytes memory _data)
        internal
        pure
        returns (string memory)
    {
        if (_data.length == 0) return "";
        string memory table = _TABLE;
        string memory result = new string(4 * ((_data.length + 2) / 3));
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let dataPtr := _data
                let endPtr := add(_data, mload(_data))
            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(_data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }

    function toBytes32(string memory _string) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

    function toString(uint256 _value) internal pure returns (string memory) {
        unchecked {
            uint256 _ptr;
            uint256 _length = Log.log10(_value) + 1;
            string memory buffer = new string(_length);
            assembly {
                _ptr := add(buffer, add(32, _length))
            }
            while (true) {
                _ptr--;
                assembly {
                    mstore8(_ptr, byte(mod(_value, 10), _SYMBOLS))
                }
                _value /= 10;
                if (_value == 0) break;
            }
            return buffer;
        }
    }

    function toHexString(uint256 _value) internal pure returns (string memory) {
        unchecked {
            return toHexString(_value, Log.log256(_value) + 1);
        }
    }

    function toHexString(address _addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(_addr)), _ADDRESS_LENGTH);
    }

    function toHexString(uint256 _value, uint256 _length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * _length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * _length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[_value & 0xf];
            _value >>= 4;
        }
        require(_value == 0);
        return string(buffer);
    }
}