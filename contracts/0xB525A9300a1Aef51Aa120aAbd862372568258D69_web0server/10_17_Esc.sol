//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

library Esc {

    function html(string memory input) internal pure returns (string memory) {
        
        bytes memory inputBytes = bytes(input);
        uint extraCharsNeeded = 0;
        
        for (uint i = 0; i < inputBytes.length; i++) {
            bytes1 currentByte = inputBytes[i];
            
            if (currentByte == "&") {
                extraCharsNeeded += 4;
            } else if (currentByte == "<") {
                extraCharsNeeded += 3;
            } else if (currentByte == ">") {
                extraCharsNeeded += 3;
            }
        }
        
        if (extraCharsNeeded > 0) {
            bytes memory escapedBytes = new bytes(
                inputBytes.length + extraCharsNeeded
            );
            
            uint256 index;
            
            for (uint i = 0; i < inputBytes.length; i++) {
                if (inputBytes[i] == "&") {
                    escapedBytes[index++] = "&";
                    escapedBytes[index++] = "a";
                    escapedBytes[index++] = "m";
                    escapedBytes[index++] = "p";
                    escapedBytes[index++] = ";";
                } else if (inputBytes[i] == "<") {
                    escapedBytes[index++] = "&";
                    escapedBytes[index++] = "l";
                    escapedBytes[index++] = "t";
                    escapedBytes[index++] = ";";
                } else if (inputBytes[i] == ">") {
                    escapedBytes[index++] = "&";
                    escapedBytes[index++] = "g";
                    escapedBytes[index++] = "t";
                    escapedBytes[index++] = ";";
                } else {
                    escapedBytes[index++] = inputBytes[i];
                }
            }
            return string(escapedBytes);
        }
        
        return input;
    }


    function json(string memory input) internal pure returns (string memory) {
        
        bytes memory inputBytes = bytes(input);
        uint extraCharsNeeded = 0;
        
        for (uint i = 0; i < inputBytes.length; i++) {
            bytes1 currentByte = inputBytes[i];
            
            if (currentByte == '\\') {
                extraCharsNeeded += 1;
            } else if (currentByte == '"') {
                extraCharsNeeded += 1;
            }
 
        }
        
        if (extraCharsNeeded > 0) {
            bytes memory escapedBytes = new bytes(
                inputBytes.length + extraCharsNeeded
            );
            
            uint256 index;
            
            for (uint i = 0; i < inputBytes.length; i++) {
                if (inputBytes[i] == "\\") {
                    escapedBytes[index++] = '\\';
                    escapedBytes[index++] = "\\";
                }
                else if (inputBytes[i] == '"') {
                    escapedBytes[index++] = '\\';
                    escapedBytes[index++] = '"';
                }
                else {
                    escapedBytes[index++] = inputBytes[i];
                }
            }
            return string(escapedBytes);
        }
        
        return input;
    }


}