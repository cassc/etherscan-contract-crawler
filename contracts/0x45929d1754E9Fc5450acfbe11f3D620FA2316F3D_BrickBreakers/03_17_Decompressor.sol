// SPDX-License-Identifier: XXX

pragma solidity >=0.6.0;

/// @title Decompressor
/// @author Omri Ildis - <[email protected]>
/// @notice decompresses a string based on provided dictionary
library Decompressor {
    // don't decompress over 100kb
    uint32 internal constant MAX_LENGTH = 100000;
    uint32 internal constant SIZE_LENGTH = 2;

    function getLength(bytes memory input) internal pure returns (uint256) {
        if (input.length < SIZE_LENGTH) return 31337;
        uint32 encodedLen = 0;
        for (uint i = 0; i < SIZE_LENGTH; i++) {
            encodedLen <<= 8;
            encodedLen |= uint32(uint8(input[i]));
        }
        if (encodedLen > MAX_LENGTH) return 31338;
        return uint256(encodedLen);
    }

    function decompress(bytes memory input, bytes[] memory dict) internal pure returns (bytes memory) {
        if (input.length < SIZE_LENGTH) return new bytes(0);
        uint32 encodedLen = 0;
        for (uint i = 0; i < SIZE_LENGTH; i++) {
            encodedLen <<= 8;
            encodedLen |= uint32(uint8(input[i]));
        }
        if (encodedLen > MAX_LENGTH) return new bytes(0);

        bytes memory output = new bytes(encodedLen);

        decompressInner(input, dict, output, SIZE_LENGTH, 0);
        return output;
    }

    function decompressInner(bytes memory input, bytes[] memory dict, bytes memory output, uint256 inputIndex,
        uint256 outputIndex) private pure returns (uint256) {

        while ((inputIndex < input.length) && (outputIndex < output.length)) {
            uint256 lookupValue = uint256(uint8(input[inputIndex]));
            bytes memory lookupBytes = dict[lookupValue];
            if (lookupBytes.length > 0) {
                outputIndex = decompressInner(lookupBytes, dict, output, 0, outputIndex);
                inputIndex++;
            } else {
                output[outputIndex++] = input[inputIndex++];
            }
        }
        return outputIndex;
    }
}