// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev Operations for decoding a segmented IPFS token uri.
 */
/// @custom:security-contact [email protected]
contract DecodeSegmentedURI {
    function _combineURISegments(bytes4 segment1, bytes32 segment2)
        internal
        pure
        returns (string memory combinedTokenURI)
    {
        bytes memory combinedBytes = abi.encodePacked(segment1, segment2);

        (bytes30 digest1, bytes30 digest2) = _bytesToTwoBytes30(combinedBytes);

        bytes memory string1 = _bytes30ToString(digest1, 48);
        bytes memory string2 = _bytes30ToString(digest2, 10);

        return string(bytes.concat(string1, string2));
    }

    function _get5BitsAsUint(bytes30 input, uint8 position)
        private
        pure
        returns (uint8)
    {
        bytes30 temp = input;
        temp = temp << (position * 5);
        bytes30 mask = 0xf80000000000000000000000000000000000000000000000000000000000;
        temp = temp & mask;
        temp = temp >> 235; // 32 * 8 - 5

        return uint8(uint240((temp)));
    }

    function _uintToChar(uint8 conv) private pure returns (bytes1) {
        if (conv < 26) {
            return bytes1(conv + 97);
        }

        return bytes1(conv + 24);
    }

    function _bytes30ToString(bytes30 input, uint8 length)
        private
        pure
        returns (bytes memory)
    {
        bytes memory bytesArray = new bytes(length);
        uint8 i = 0;

        for (i = 0; i < length; i++) {
            uint8 bit = _get5BitsAsUint(input, i);
            bytesArray[i] = _uintToChar(bit);
        }

        return bytesArray;
    }

    function _bytesToTwoBytes30(bytes memory input)
        private
        pure
        returns (bytes30 digest1, bytes30 digest2)
    {
        uint256 i = 0;
        uint256 wordlength = input.length;
        uint256 midpoint = 30;

        bytes memory digest1Bytes = new bytes(midpoint);
        bytes memory digest2Bytes = new bytes(wordlength - midpoint);

        for (i = 0; i < midpoint; i++) {
            digest1Bytes[i] = input[i];
        }

        for (i = 0; i < wordlength - midpoint; i++) {
            digest2Bytes[i] = input[i + midpoint];
        }

        return (bytes30(digest1Bytes), bytes30(digest2Bytes));
    }
}