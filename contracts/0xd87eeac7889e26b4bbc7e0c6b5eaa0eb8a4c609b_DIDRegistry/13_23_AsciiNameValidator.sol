// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;
import "./INameValidator.sol";

contract AsciiNameValidator is INameValidator {
    uint256 constant CHAR_ENGLISH = 1;
    uint256 constant CHAR_DIGITS = 2;
    uint256 constant CHAR_MINUS = 4;

    function validateName(string memory name)
        external
        pure
        override
        returns (uint256)
    {
        return checkString(name);
    }

    /**
     * Convert utf-8 string to unicode char and check each char, return how many unicode chars.
     */
    function checkString(string memory s) internal pure returns (uint256) {
        bytes memory bs = bytes(s);
        uint256 i = 0;
        uint256 len = 0;
        uint256 has_chars = 0;
        uint256 last_char = 0;
        uint256 current_char = 0;
        while (i < bs.length) {
            uint8 b1 = uint8(bs[i]);
            i++;
            if (b1 & 0x80 == 0) {
                // 0xxxxxxx
                current_char = checkUnicodeChar(b1);
                if (last_char == CHAR_MINUS && current_char == CHAR_MINUS) {
                    revert("Cannot contains '--'");
                }
                has_chars |= current_char;
                len++;
            } else {
                revert("Invalid char");
            }
            last_char = current_char;
        }
        // disallow first and last '-':
        if (bs[0] == "-" || bs[bs.length - 1] == "-") {
            revert("Cannot use minus at first or last.");
        }
        return len;
    }

    function checkUnicodeChar(uint16 b) internal pure returns (uint256) {
        // ASCII: a-z:
        if ((b >= 0x61 && b <= 0x7a)) {
            return CHAR_ENGLISH;
        }
        // 0-9:
        if ((b >= 0x30 && b <= 0x39)) {
            return CHAR_DIGITS;
        }
        // minus '-':
        if (b == 0x2d) {
            return CHAR_MINUS;
        }
        revert("Unsupported char code");
    }
}