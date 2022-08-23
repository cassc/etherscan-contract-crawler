// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Helpers {
    // https://stackoverflow.com/questions/67893318/solidity-how-to-represent-bytes32-as-string/69266989#69266989
    /// @notice converting bytes16 to Hex String
    /// @param data bytes16 input
    /// @return result string output
    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result =
            (bytes32(data) &
                0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
            ((bytes32(data) &
                0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
                64);
        result =
            (result &
                0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
            ((result &
                0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
                32);
        result =
            (result &
                0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
            ((result &
                0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
                16);
        result =
            (result &
                0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
            ((result &
                0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
                8);
        result =
            ((result &
                0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
                4) |
            ((result &
                0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
                8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
                (((uint256(result) +
                    0x0606060606060606060606060606060606060606060606060606060606060606) >>
                    4) &
                    0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
                39
        ); // 7 for upper case
    }

    /// @notice converting bytes32 to Hex String
    /// @param data bytes32 input
    /// @return result string output
    function toHex(bytes32 data) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "0x",
                    toHex16(bytes16(data)),
                    toHex16(bytes16(data << 128))
                )
            );
    }

    // https://ethereum.stackexchange.com/questions/7702/how-to-convert-byte-array-to-bytes32-in-solidity/28452
    /// @notice converting bytes to bytes16
    /// @param b bytes input
    /// @param offset uint256 offset
    /// @return out bytes16 outout
    function bytesToBytes16(bytes memory b, uint256 offset)
        internal
        pure
        returns (bytes16 out)
    {
        for (uint256 i = 0; i < 16; i++) {
            out |= bytes16(b[offset + i] & 0xFF) >> (i * 8);
        }
    }
    
    /// @notice Convert public key from bytes to string output
    /// @param pubKey The public key
    /// @return The public key in string format
    function pubKeyToString(bytes memory pubKey)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    toHex(bytes32(pubKey)),
                    toHex16((bytesToBytes16(pubKey, 32)))
                )
            );
    }
}