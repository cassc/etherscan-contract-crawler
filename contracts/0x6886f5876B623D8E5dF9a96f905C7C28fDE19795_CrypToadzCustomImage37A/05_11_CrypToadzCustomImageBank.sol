// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "./BufferUtils.sol";

library CrypToadzCustomImageBank {
    function getCustomImageCompressed(mapping(uint8 => uint16) storage lengths, mapping(uint8 => address) storage data)
        internal
        view
        returns (bytes memory buffer)
    {
        uint256 size;
        uint8 count;
        while (lengths[count] != 0) {
            size += lengths[count++];
        }
        buffer = DynamicBuffer.allocate(size);
        for (uint8 i = 0; i < count; i++) {
            bytes memory chunk = BufferUtils.decompress(
                data[i],
                lengths[i]
            );            
            DynamicBuffer.appendUnchecked(buffer, chunk);
        }
    }

    function getCustomImageUncompressed(mapping(uint8 => uint16) storage lengths, mapping(uint8 => address) storage data)
        internal
        view
        returns (bytes memory buffer)
    {
        uint256 size;
        uint8 count;
        while (lengths[count] != 0) {
            size += lengths[count++];
        }
        buffer = DynamicBuffer.allocate(size);
        for (uint8 i = 0; i < count; i++) {
            bytes memory chunk = SSTORE2.read(data[i]);            
            DynamicBuffer.appendUnchecked(buffer, chunk);
        }
    }

    function getCustomImageSingleCompressed(uint16 length, address data)
        internal
        view
        returns (bytes memory buffer)
    {
        return BufferUtils.decompress(data, length);
    }

    function getCustomImageSingleUncompressed(address data)
        internal
        view
        returns (bytes memory buffer)
    {
        return SSTORE2.read(data);
    }
}