// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library utils {
    function toString(
        uint256 value
    ) internal pure returns (string memory) {
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

    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(
        bytes memory data
    ) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = _TABLE;

        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            let tablePtr := add(table, 1)

            let resultPtr := add(result, 32)

            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(
                    add(tablePtr, and(shr(18, input), 0x3F))
                ))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(
                    add(tablePtr, and(shr(12, input), 0x3F))
                ))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(
                    add(tablePtr, and(shr(6, input), 0x3F))
                ))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(
                    add(tablePtr, and(input, 0x3F))
                ))
                resultPtr := add(resultPtr, 1) // Advance
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }
}