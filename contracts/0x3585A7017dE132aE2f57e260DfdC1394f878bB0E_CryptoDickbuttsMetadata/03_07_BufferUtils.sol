// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./SSTORE2.sol";
import "./InflateLib.sol";
import "./Errors.sol";

library BufferUtils {

    function decompress(address compressed, uint256 decompressedLength)
        internal
        view
        returns (bytes memory)
    {
        (InflateLib.ErrorCode code, bytes memory buffer) = InflateLib.puff(
            SSTORE2.read(compressed),
            decompressedLength
        );
        if (code != InflateLib.ErrorCode.ERR_NONE)
            revert FailedToDecompress(uint256(code));
        if (buffer.length != decompressedLength)
            revert InvalidDecompressionLength(
                decompressedLength,
                buffer.length
            );
        return buffer;
    }

    function advanceToTokenPosition(uint256 tokenId, bytes memory buffer)
        internal
        pure
        returns (uint256 position, uint8 length)
    {
        uint256 id;
        while (id != tokenId) {
            (id, position) = BufferUtils.readUInt32(position, buffer);
            (length, position) = BufferUtils.readByte(position, buffer);
            if (id != tokenId) {
                position += length;
                if (position >= buffer.length) return (position, 0);
            }
        }
        return (position, length);
    }

    function readUInt32(uint256 position, bytes memory buffer)
        internal
        pure
        returns (uint32, uint256)
    {
        uint8 d1 = uint8(buffer[position++]);
        uint8 d2 = uint8(buffer[position++]);
        uint8 d3 = uint8(buffer[position++]);
        uint8 d4 = uint8(buffer[position++]);
        return ((16777216 * d4) + (65536 * d3) + (256 * d2) + d1, position);
    }

    function readByte(uint256 position, bytes memory buffer)
        internal
        pure
        returns (uint8, uint256)
    {
        uint8 value = uint8(buffer[position++]);
        return (value, position);
    }
}