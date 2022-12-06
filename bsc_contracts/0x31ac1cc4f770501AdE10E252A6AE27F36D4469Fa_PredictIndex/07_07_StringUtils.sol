// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StringUtils {

    struct slice {
        uint256 _len;
        uint256 _ptr;
    }


    /// @dev Extracts an slice from a string
    function substring(string memory base, int16 _length, int16 offset) 
        public 
        pure 
        returns (string memory) 
    {
        bytes memory baseBytes = bytes(base);

        assert(uint16(offset + _length) <= baseBytes.length);

        string memory tmp = new string(uint16(_length));
        bytes memory tmpBytes = bytes(tmp);

        uint16 j = 0;
        for (uint16 i = uint16(offset); i < uint16(offset + _length); i++) {
            tmpBytes[j++] = baseBytes[i];
        }

        return string(tmpBytes);
    }

    /// @dev Converts string number to unsigned integer format
    function stringToUint(string memory s) public pure returns (uint256 result) {
        bytes memory b = bytes(s);
        for (uint16 i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
    }
    
    /// @dev Converts a `uint256` to its ASCII `string` decimal representation.
    function uintToString(uint256 value) public pure returns (string memory) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
   
    /// @dev Converts string float number to unsigned integer format. Performs
    /// multiplication to eliminate decimals.
    function stringFloatToUint(
        string memory numText, 
        string memory separator, 
        uint16 decimals
    ) 
        public pure returns(uint256 value) 
    {    
        uint16 textDecimals = lenRightSplit(numText, separator);
        if (textDecimals < decimals) decimals -= textDecimals;
        else decimals = 0;

        value = stringToUint(numText) * 10**decimals;
    }
    
    /// @notice Returns the length of the text at the right of needle.
    function lenRightSplit(string memory self, string memory needle) 
        public 
        pure 
        returns(uint16) 
    {
        slice memory selfSlice = toSlice(self);
        slice memory needleSlice = toSlice(needle);
        uint256 ptr = findPtr(selfSlice._len, selfSlice._ptr, needleSlice._len, needleSlice._ptr);
        
        return uint16(selfSlice._len - (ptr - selfSlice._ptr) - 1);
    }


    /// @dev Returns a slice containing the entire string.
    /// @param self The string to make a slice from.
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen, 
        uint256 selfptr, 
        uint256 needlelen, 
        uint256 needleptr
    ) 
        private pure returns (uint256) 
    {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }
}