pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

library Strings {
    function len(string memory str) internal pure returns(uint) {
        return(bytes(str).length);
    }

    function concat(string memory str1, string memory str2) internal pure returns(string memory) {
        return(string(abi.encodePacked(str1, str2)));
    }

    function compare(string memory str1, string memory str2) internal pure returns(bool) {
        return(memCompare(bytes(str1), bytes(str2)));
    }

    function substr(string memory str, uint startIndex, uint length) internal pure returns( string memory s) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(length);
        uint _len = strBytes.length;
        for(uint i = startIndex; i < startIndex+length; i++) {
            if (i >= _len)
                break;
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function strPos(string memory str, string memory needle) internal pure returns(bool found, uint pos) {
        bytes memory strBytes = bytes(str);
        bytes memory needleBytes = bytes(needle);
        pos = 0;
        found = false;
        for(uint i = 0; i < strBytes.length; i++) {
            for (uint j = 0; j < needleBytes.length; j++) {
                if (strBytes[i + j] == needleBytes[j]) {
                    found = true;
                } else {
                    found = false;
                    break;
                }
            }
            if (found) {
                pos = i;
                break;
            }
        }
    }

    function strPos(string memory str, string memory needle, uint offset) internal pure returns(bool found, uint pos) {
        bytes memory strBytes = bytes(str);
        bytes memory needleBytes = bytes(needle);
        pos = 0;
        found = false;
        if (offset == 0)
            return(found, pos);
        uint offsetCount = 0;
        for(uint i = 0; i < strBytes.length; i++) {
            for (uint j = 0; j < needleBytes.length; j++) {
                if (strBytes[i + j] == needleBytes[j]) {
                    found = true;
                } else {
                    found = false;
                    break;
                }
            }
            if (found) {
                offsetCount++;
                if (offsetCount == offset) {
                    pos = i;
                    break;
                }
            else
                found = false;
            }
        }
    }

    function appendUint(string memory str, uint value) internal pure returns(string memory) {
        if (value == 0) {
            return("0");
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory result = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            result[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return(concat(str, string(result)));
    }

    function strToUint(string memory str) internal pure returns(uint result) {
        bytes memory bStr = bytes(str);
        result = 0;
        for (uint i = 0; i < bStr.length; i++) {
            uint8 char = uint8(bStr[i]);
            if (char >= 48 && char <= 57)
                result = result * 10 + (char - 48);
            else
                break;
        }
    }

    function appendSpace(string memory str) internal pure returns(string memory) {
        return(concat(str," "));
    } 
    
    function appendNewLine(string memory str) internal pure returns(string memory) {
        return(concat(str,"\n"));
    } 
    
    function stringToByte(string memory str) internal pure returns(byte) {
        byte bStrN;
        assembly {
            bStrN := mload(add(str, 32))
        }
        return(bStrN);
    }

//****************************************************************************
//* Internal Functions
//****************************************************************************
    function memCompare(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

}