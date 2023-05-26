// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title AuxHelper16
 * @author @KC, NFT Culture
 * @dev Helper class for ERC721a Aux storage, using 16 bit ints.
 */
abstract contract AuxHelper16 {
    function _pack16(uint16 left16, uint16 leftCenter16, uint16 rightCenter16, uint16 right16) internal pure returns (uint64) {
        return (uint64(left16) << 48) | (uint64(leftCenter16) << 32) | (uint64(rightCenter16) << 16) | uint16(right16);
    }

    function _unpack16(uint64 aux) internal pure returns (uint16 left16, uint16 leftCenter16, uint16 rightCenter16, uint16 right16) {
        return (uint16(aux >> 48), uint16(aux >> 32), uint16(aux >> 16), uint16(aux));
    }
}