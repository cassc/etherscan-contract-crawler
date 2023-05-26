// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library GoatLibrary {
    // Provides a function for encoding some bytes in base64
    // By Brecht Devos <[email protected]>
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function parseInt(string memory _a) internal pure returns (uint8 _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint8 minty = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                minty *= 10;
                minty += uint8(bresult[i]) - 48;
            }
        }
        return minty;
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
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

    function selectTraitSoup(uint256 _rnd) internal pure returns(uint256) {
        if(_rnd < 2) { return 0; }
        if(_rnd < 6) { return 1; }
        if(_rnd < 11) { return 2; }
        if(_rnd < 18) { return 3; }
        if(_rnd < 26) { return 4; }
        if(_rnd < 34) { return 5; }
        if(_rnd < 42) { return 6; }
        if(_rnd < 52) { return 7; }
        if(_rnd < 65) { return 8; }
        if(_rnd < 80) { return 9; }
        return 10;
    }

    function selectTraitBowl(uint256 _rnd) internal pure returns(uint256) {
        if(_rnd < 2) { return 0; }
        if(_rnd < 6) { return 1; }
        if(_rnd < 11) { return 2; }
        if(_rnd < 18) { return 3; }
        if(_rnd < 25) { return 4; }
        if(_rnd < 33) { return 5; }
        if(_rnd < 42) { return 6; }
        if(_rnd < 52) { return 7; }
        if(_rnd < 64) { return 8; }
        return 9;
    }

    function selectTraitFur(uint256 _rnd) internal pure returns(uint256) {
        if(_rnd < 2) { return 0; }
        if(_rnd < 5) { return 1; }
        if(_rnd < 9) { return 2; }
        if(_rnd < 14) { return 3; }
        if(_rnd < 24) { return 4; }
        if(_rnd < 34) { return 5; }
        if(_rnd < 50) { return 6; }
        if(_rnd < 70) { return 7; }
        return 8;
    }

    function selectTraitTeeth(uint256 _rnd) internal pure returns(uint256) {
        if(_rnd < 2) { return 0; }
        if(_rnd < 7) { return 1; }
        if(_rnd < 17) { return 2; }
        if(_rnd < 35) { return 3; }
        if(_rnd < 60) { return 4; }
        return 5;
    }

    function selectTraitHorns(uint256 _rnd) internal pure returns(uint256) {
        if(_rnd < 5) { return 0; }
        if(_rnd < 15) { return 1; }
        if(_rnd < 50) { return 2; }
        return 3;
    }

    function selectTraitHats(uint256 _rnd) internal pure returns(uint256) {
        if(_rnd < 1) { return 0; }
        if(_rnd < 3) { return 1; }
        if(_rnd < 6) { return 2; }
        if(_rnd < 9) { return 3; }
        if(_rnd < 15) { return 4; }
        if(_rnd < 22) { return 5; }
        if(_rnd < 29) { return 6; }
        if(_rnd < 38) { return 7; }
        if(_rnd < 48) { return 8; }
        if(_rnd < 59) { return 9; }
        return 10;
    }
    
    function selectTraitEyes(uint256 _rnd) internal pure returns(uint256) {
        if(_rnd < 1) { return 0; }
        if(_rnd < 3) { return 1; }
        if(_rnd < 6) { return 2; }
        if(_rnd < 11) { return 3; }
        if(_rnd < 19) { return 4; }
        if(_rnd < 31) { return 5; }
        if(_rnd < 49) { return 6; }
        if(_rnd < 72) { return 7; }
        return 8;
    }
}