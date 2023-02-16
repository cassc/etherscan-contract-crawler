// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @author iain and openzeppelin
// @dev modified from  openzeppelin-contracts/contracts/utils/Strings.sol
library StringsBytes32 {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(bytes32 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * 32);
        for (int256 i = 2 * 32 - 1; i >= 0; --i) {
            buffer[uint256(i)] = _SYMBOLS[uint256(value) & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}