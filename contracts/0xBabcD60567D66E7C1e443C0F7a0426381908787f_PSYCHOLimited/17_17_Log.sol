// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

library Log {
    function log2(uint256 _value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (_value >> 128 > 0) {
                _value >>= 128;
                result += 128;
            }
            if (_value >> 64 > 0) {
                _value >>= 64;
                result += 64;
            }
            if (_value >> 32 > 0) {
                _value >>= 32;
                result += 32;
            }
            if (_value >> 16 > 0) {
                _value >>= 16;
                result += 16;
            }
            if (_value >> 8 > 0) {
                _value >>= 8;
                result += 8;
            }
            if (_value >> 4 > 0) {
                _value >>= 4;
                result += 4;
            }
            if (_value >> 2 > 0) {
                _value >>= 2;
                result += 2;
            }
            if (_value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function log10(uint256 _value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (_value >= 10**64) {
                _value /= 10**64;
                result += 64;
            }
            if (_value >= 10**32) {
                _value /= 10**32;
                result += 32;
            }
            if (_value >= 10**16) {
                _value /= 10**16;
                result += 16;
            }
            if (_value >= 10**8) {
                _value /= 10**8;
                result += 8;
            }
            if (_value >= 10**4) {
                _value /= 10**4;
                result += 4;
            }
            if (_value >= 10**2) {
                _value /= 10**2;
                result += 2;
            }
            if (_value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    function log256(uint256 _value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (_value >> 128 > 0) {
                _value >>= 128;
                result += 16;
            }
            if (_value >> 64 > 0) {
                _value >>= 64;
                result += 8;
            }
            if (_value >> 32 > 0) {
                _value >>= 32;
                result += 4;
            }
            if (_value >> 16 > 0) {
                _value >>= 16;
                result += 2;
            }
            if (_value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }
}