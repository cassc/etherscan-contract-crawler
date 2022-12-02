// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

/***
 * @title AdvancedStakingBridgedDataDecoder
 * @dev It encode (pack) and decodes (unpack) messages for bridging them between networks
 */
abstract contract AdvancedStakingBridgedDataCoder {
    function _encodeBridgedData(
        uint24 _nonce,
        bytes4 action,
        bytes memory message
    ) internal pure returns (bytes memory content) {
        content = abi.encodePacked(_nonce, action, message);
    }

    // For efficiency we use "packed" (rather than "ABI") encoding.
    // It results in shorter data, but requires custom unpack function.
    function _decodeBridgedData(bytes memory content)
        internal
        pure
        returns (
            uint256 _nonce,
            bytes4 action,
            bytes memory message
        )
    {
        require(content.length >= 7, "ABD:WRONG_LENGTH");

        _nonce =
            (uint256(uint8(content[0])) << 16) |
            (uint256(uint8(content[1])) << 8) |
            uint256(uint8(content[2]));

        action = bytes4(
            uint32(
                (uint256(uint8(content[3])) << 24) |
                    (uint256(uint8(content[4])) << 16) |
                    (uint256(uint8(content[5])) << 8) |
                    uint256(uint8(content[6]))
            )
        );

        uint256 curPos = 7;
        uint256 msgLength = content.length - curPos;
        message = new bytes(msgLength);
        if (msgLength > 0) {
            uint256 i = 0;
            while (i < msgLength) {
                message[i++] = content[curPos++];
            }
        }
    }
}