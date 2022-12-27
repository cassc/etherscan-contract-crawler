// SPDX-License-Identifier: None
pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
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

    function doidlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else {
                len++;
                if (b < 0xE0) {
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
        }
        return len;
    }

    struct Slice {
        uint256 _len;
        uint256 _ptr;
    }

    /**
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (Slice memory) {
        uint256 ptr;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            ptr := add(self, 0x20)
        }
        return Slice(bytes(self).length, ptr);
    }

    /**
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return ret The hash of the slice.
     */
    function keccak(Slice memory self) internal pure returns (bytes32 ret) {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /**
     * @dev Returns the slice of the original slice.
     * @param self The slice to hash.
     * @param index The index of original slice for slice ptr.
     * @param len The sub slice length.
     * @return The slice of the original slice.
     */
    function slice(
        Slice memory self,
        uint256 index,
        uint256 len
    ) internal pure returns (Slice memory) {
        return Slice(len, self._ptr + index);
    }
}