// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library Bytes32 {
    /// @notice Converts bytes32 to base32 string.
    /// @param value value to convert.
    /// @return the converted base32 string.
    function toBase32String(bytes32 value) internal pure returns (string memory) {
        unchecked {
            bytes32 base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;
            uint256 i = uint256(value);
            uint256 k = 52;
            bytes memory bstr = new bytes(k);
            bstr[--k] = base32Alphabet[uint8((i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (i % (2**s)) << (5-s)
            i /= 8;
            while (k > 0) {
                bstr[--k] = base32Alphabet[i % 32];
                i /= 32;
            }
            return string(bstr);
        }
    }

    /// @notice Converts a bytes32 value to an ASCII string, trimming the tailing zeros.
    /// @param value value to convert.
    /// @return the converted ASCII string.
    function toASCIIString(bytes32 value) internal pure returns (string memory) {
        unchecked {
            if (value == 0x00) return "";
            bytes memory bytesString = bytes(abi.encodePacked(value));
            uint256 pos = 31;
            while (true) {
                if (bytesString[pos] != 0) break;
                --pos;
            }
            bytes memory asciiString = new bytes(pos + 1);
            for (uint256 i; i <= pos; ++i) {
                asciiString[i] = bytesString[i];
            }
            return string(asciiString);
        }
    }
}