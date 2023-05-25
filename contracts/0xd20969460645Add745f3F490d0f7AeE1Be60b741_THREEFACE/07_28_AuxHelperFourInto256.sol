// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title AuxHelperFourInto256
 * @author @KC, NFT Culture
 * @dev Helper class for ERC721a Aux-style storage. This flavor packs 4 64bit fields into a 256 bit int.
 */
abstract contract AuxHelperFourInto256 {
    function _pack64(uint64 left64, uint64 leftCenter64, uint64 rightCenter64, uint64 right64) internal pure returns (uint256) {
        return (uint256(left64) << 192) | (uint256(leftCenter64) << 128) | (uint256(rightCenter64) << 64) | uint64(right64);
    }

    function _unpack64(uint256 aux) internal pure returns (uint64 left64, uint64 leftCenter64, uint64 rightCenter64, uint64 right64) {
        return (uint64(aux >> 192), uint64(aux >> 128), uint64(aux >> 64), uint64(aux));
    }
}