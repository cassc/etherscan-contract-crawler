// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library StringUtils {
    
    /**
     * convert string to bytes32
     * @param source string variable
     */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    /**
     * convert bytes32 to string
     * @param _bytes32 bytes32 variable
     */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    
    /**
     * convert string to lowercase
     */
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) internal pure returns (uint8 ret) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            ret = c - uint8(bytes1('0'));
        } else
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            ret = 10 + c - uint8(bytes1('a'));
        } else
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            ret = 10 + c - uint8(bytes1('A'));
        }
    }
    
    // Convert an hexadecimal string to raw bytes
    function fromHex(string memory s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }
}