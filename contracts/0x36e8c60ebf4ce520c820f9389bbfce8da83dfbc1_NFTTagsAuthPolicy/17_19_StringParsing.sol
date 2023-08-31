// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library StringParsing {
    /**
     * @dev Parses a UTF8 string of digits representing an unsigned integer.
     */
    function parseUint256(bytes calldata b) internal pure returns (bool valid, uint256 parsed) {
        uint256 i;
        parsed = 0;
        for (i = 0; i < b.length; i++) {
            if (b[i] < bytes1(0x30) || b[i] > bytes1(0x39)) {
                return (false, 0);
            }
            uint256 c = uint(uint8(b[i])) - 48;
            parsed = parsed * 10 + c;
        }
        return (true, parsed);
    }
}