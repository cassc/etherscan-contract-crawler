// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    /**
     * @dev Checks the string for RFC3986 reserved characters.
     *      Includes a few more extra chars for security. Specifically, percent encoding is not allowed.
     *
     * @param s The string to check
     * @return T/F
     */
    function validateUriCharset(string memory s) internal pure returns (bool) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        bytes1 b0 = bytes(s)[0];
        if (b0==0x2d||b0==0x5f||b0==0x7e) {  // not allowed: - _ ~
            return false;
        }
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
                if (b<0x2d||b==0x2e||b==0x2f||(b>=0x3a&&b<=0x40)||b==0x5b||b==0x5c||b==0x5d||b==0x5e||b==0x60||b==0x7b||b==0x7c||b==0x7d||b==0x7f) {
                    return false;
                }
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return true;
    }

    /**
     * @dev Apply UTS-46 normalization to a string. (implementation deviates from the standard)
     *
     * @param s The string to normalize
     * @return T/F
     */
    function UTS46Normalize(string memory s) internal pure returns (string memory) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        bytes1 b0 = bytes(s)[0];

        if (b0==0x2d||b0==0x5f||b0==0x7e) {  // not allowed in first position: - _ ~
            revert("invalid charset");
        }
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                if (b<0x2d||b==0x2e||b==0x2f||(b>=0x3a&&b<=0x40)||b==0x5b||b==0x5c||b==0x5d||b==0x5e||b==0x60||b==0x7b||b==0x7c||b==0x7d||b==0x7f) {
                    revert("invalid charset");
                }
                if (b>=0x41&&b<=0x5a) {
                    bytes(s)[i] = bytes1(uint8(b) + 32);
                }
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return s;
    }
}