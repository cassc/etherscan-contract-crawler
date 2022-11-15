// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library UriEncode {
    string internal constant _TABLE = "0123456789abcdef";

    function uriEncode(string memory uri)
        internal
        pure
        returns (string memory)
    {
        bytes memory bytesUri = bytes(uri);

        string memory table = _TABLE;

        // Max size is worse case all chars need to be encoded
        bytes memory result = new bytes(3 * bytesUri.length);

        /// @solidity memory-safe-assembly
        assembly {
            // Get the lookup table
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Keep track of the final result size string length
            let resultSize := 0

            for {
                let dataPtr := bytesUri
                let endPtr := add(bytesUri, mload(bytesUri))
            } lt(dataPtr, endPtr) {

            } {
                // advance 1 byte
                dataPtr := add(dataPtr, 1)
                // bytemask out a char
                let input := and(mload(dataPtr), 255)

                // Check if is valid URI character
                let isValidUriChar := or(
                    and(gt(input, 96), lt(input, 134)), // a 97 / z 133
                    or(
                        and(gt(input, 64), lt(input, 91)), // A 65 / Z 90
                        or(
                          and(gt(input, 47), lt(input, 58)), // 0 48 / 9 57
                          or(
                            or(
                              eq(input, 46), // . 46
                              eq(input, 95)  // _ 95
                            ),
                            or(
                              eq(input, 45),  // - 45
                              eq(input, 126)  // ~ 126
                            )
                          )
                        )
                    )
                )

                switch isValidUriChar
                // If is valid uri character copy character over and increment the result
                case 1 {
                    mstore8(resultPtr, input)
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 1)
                }
                // If the char is not a valid uri character, uriencode the character
                case 0 {
                    mstore8(resultPtr, 37)
                    resultPtr := add(resultPtr, 1)
                    // table[character >> 4] (take the last 4 bits)
                    mstore8(resultPtr, mload(add(tablePtr, shr(4, input))))
                    resultPtr := add(resultPtr, 1)
                    // table & 15 (take the first 4 bits)
                    mstore8(resultPtr, mload(add(tablePtr, and(input, 15))))
                    resultPtr := add(resultPtr, 1)
                    resultSize := add(resultSize, 3)
                }
            }

            // Set size of result string in memory
            mstore(result, resultSize)
        }

        return string(result);
    }
}