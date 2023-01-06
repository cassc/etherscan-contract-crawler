// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Strings library. Provides additional functionality around string formatting.
 */
library Strings {
    /**
     * @dev uri returns padded hex string representation of the uint. Does not include 0x.
     * For use in URI replacement strategy for 1155 token URI
     * @param _i Uint to be processed into a string.
     * @return A string representing a uint256, but with padded zeroes and without the 0x prefix.
     */
    function toPaddedHexString(uint256 _i)
        internal
        pure
        returns (string memory)
    {
        uint256 j = _i;
        bytes memory bstr = new bytes(64);
        uint256 k = 63;
        // Get each individual ASCII
        while (j != 0 && k >= 0) {
            if (j % 16 >= 10) {
                bstr[k] = bytes1(uint8(87 + (j % 16)));
            } else {
                bstr[k] = bytes1(uint8(48 + (j % 16)));
            }
            k -= 1;
            j /= 16;
        }
        for (uint256 i = 0; i <= k; ++i) {
            bstr[i] = bytes1(uint8(48));
        }
        // Convert to string
        return string(bstr);
    }
}