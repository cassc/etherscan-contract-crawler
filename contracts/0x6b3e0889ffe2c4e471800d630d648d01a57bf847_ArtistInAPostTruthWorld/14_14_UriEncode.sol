// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library UriEncode {
    string internal constant _TABLE = "0123456789abcdef";

    function uriEncode(
        string memory uri
    ) internal pure returns (string memory) {
        bytes memory bytesUri = bytes(uri);

        string memory table = _TABLE;

        bytes memory result = new bytes(3 * bytesUri.length);

        /// @solidity memory-safe-assembly
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            let resultSize := 0

            for {
                let dataPtr := bytesUri
                let endPtr := add(bytesUri, mload(bytesUri))
            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 1)
                let char := and(mload(dataPtr), 255)

                let isInvalidUriChar := or(
                    or(
                        lt(char, 33), // lower than "!"
                        gt(char, 122) // higher than "z"
                    ),
                    or(
                        or(
                            eq(char, 37), // "%"
                            or(
                                eq(char, 60), // "<"
                                eq(char, 62) // ">"
                            )
                        ),
                        or(
                            and(gt(char, 90), lt(char, 95)), // "[\]^"
                            eq(char, 96) // "`"
                        )
                    )
                )
                if eq(char, 35) { isInvalidUriChar := 1 }

                switch isInvalidUriChar
                case 0 {
                    mstore8(resultPtr, char)
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 1)
                }
                case 1 {
                    mstore8(resultPtr, 37)
                    resultPtr := add(resultPtr, 1)
                    mstore8(resultPtr, mload(add(tablePtr, shr(4, char))))
                    resultPtr := add(resultPtr, 1)
                    mstore8(resultPtr, mload(add(tablePtr, and(char, 15))))
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 3)
                }
            }

            mstore(result, resultSize)
        }

        return string(result);
    }
}