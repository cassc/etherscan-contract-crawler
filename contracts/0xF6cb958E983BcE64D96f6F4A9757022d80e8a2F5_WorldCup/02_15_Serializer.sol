// SPDX-License-Identifier: GOFUCKYOURSELF
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Serializer {
    // Methods to serialize and unserialize the Bracket submission
    // This is needed in order to store the bracket as a key in a map.
    // Takes a bracket [1,2,3] and returns a string "1,2,3"
    function toStr(uint[] memory list) public pure returns(string memory res) {
        for (uint i = 0; i < list.length; i++) { 
            res = string(abi.encodePacked(res, i == 0 ? "" : ",", Strings.toString(list[i])));
        }
    }

    // Takes a string key "1,2,3" and returns an array [1,2,3] 
    function toList(string memory list) public pure returns(uint[] memory) {
        // Convert the string to a bytes so we can read through it. 
        bytes memory buffer = bytes(list);
        uint[] memory bracket; 

        // default; round group
        if(buffer.length >= 44) {
            bracket = new uint[](31);
        // 34 <= length <= 44 => round 16 
        } else if(buffer.length >= 34) {
            bracket = new uint[](15);
        // 13 <= length 20 => round QF 
        } else /*if(buffer.length >= 13)*/ {
            bracket = new uint[](7);
        }

        uint i = 0;
        uint j = 0;

        // Read the buffer two characters at a time.
        while(i < buffer.length) {
            uint8 tens = uint8(buffer[i]);

            // If we only have one more character, then it must be a number, 
            // so we push it and break
            if(i + 1 == buffer.length) {
                bracket[j] = uint(tens % 16);
                break;
            }

            uint8 ones = uint8(buffer[i+1]);

            // 44 is the uint8 representation of ","
            // Case: "1" "," => push one, advance two space
            if(ones == 44) { 
                // Since it's hex, we mod 16 to convert to decimal. 
                bracket[j] = uint(tens % 16);
                j++;
                i += 2;
            } else { 
                // Case: "1" "5" => parse tens ones and push, advance three spaces 
                // Since it's hex, we mod 16 to convert to decimal. 
                bracket[j] = uint(tens % 16) * 10 + uint(ones % 16);

                j++;
                i += 3;
            }
        }

        return bracket;
    }

    // // deprecate me 
    // function arraysEqual(uint[] memory a, uint[] memory b) public pure returns(bool) {
    //     if(a.length != b.length) {
    //         return false;
    //     }

    //     for(uint i = 0; i < a.length; i++) {
    //         if(a[i] != b[i]) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }
}