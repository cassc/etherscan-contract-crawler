// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title AuxHelper32
 * @author @NiftyMike | NFT Culture
 * @dev Helper class for ERC721a Aux storage, using 32 bit ints.
 */
abstract contract AuxHelper32 {
    function _pack32(uint32 left32, uint32 right32) internal pure returns (uint64) {
        return (uint64(left32) << 32) | uint32(right32);
    }

    function _unpack32(uint64 aux) internal pure returns (uint32 left32, uint32 right32) {
        return (uint32(aux >> 32), uint32(aux));
    }
}