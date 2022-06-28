// SPDX-License-Identifier: BSD-3-Clause

import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.13;

library StringUtils {
    // Check if haystack has any invalid character for JSON value:
    // - ": 0x22
    // - \: 0x5c
    // - any control characters: 0x00-0x1f (except new line = 0x0a), 0x7f
    function validJSONValue(string calldata haystack) internal pure returns (bool) {
        bytes memory haystackBytes = bytes(haystack);
        uint256 length = haystackBytes.length;
        for (uint256 i; i != length;) {
            bytes1 char = haystackBytes[i];
            if ((char < 0x20 && char != 0x0a) || char == 0x22 || char == 0x5c || char == 0x7f) {
                return false;
            }

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function address2str(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint160(addr), 20);
    }
}