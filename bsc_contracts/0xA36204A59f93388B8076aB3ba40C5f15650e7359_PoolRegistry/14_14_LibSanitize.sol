// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title Lib Sanitize - Sanitize strings in smart contracts.
/// @author Gabriele Rigo - <[email protected]>
library LibSanitize {
    function assertIsValidCheck(string memory str) internal pure {
        bytes memory bStr = bytes(str);
        uint256 arrayLength = bStr.length;
        require(bStr[0] != bytes1(uint8(32)), "LIBSANITIZE_SPACE_AT_BEGINNING_ERROR");
        require(bStr[arrayLength - 1] != bytes1(uint8(32)), "LIBSANITIZE_SPACE_AT_END_ERROR");
        for (uint256 i = 0; i < arrayLength; i++) {
            if (
                (bStr[i] < bytes1(uint8(48)) ||
                    bStr[i] > bytes1(uint8(122)) ||
                    (bStr[i] > bytes1(uint8(57)) && bStr[i] < bytes1(uint8(65))) ||
                    (bStr[i] > bytes1(uint8(90)) && bStr[i] < bytes1(uint8(97)))) && bStr[i] != bytes1(uint8(32))
            ) revert("LIBSANITIZE_SPECIAL_CHARACTER_ERROR");
        }
    }

    function assertIsLowercase(string memory str) internal pure {
        bytes memory bStr = bytes(str);
        uint256 arrayLength = bStr.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if ((bStr[i] >= bytes1(uint8(65))) && (bStr[i] <= bytes1(uint8(90))))
                revert("LIBSANITIZE_LOWERCASE_CHARACTER_ERROR");
        }
    }

    function assertIsUppercase(string memory str) internal pure {
        bytes memory bStr = bytes(str);
        uint256 arrayLength = bStr.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if ((bStr[i] >= bytes1(uint8(97))) && (bStr[i] <= bytes1(uint8(122))))
                revert("LIBSANITIZE_UPPERCASE_CHARACTER_ERROR");
        }
    }
}