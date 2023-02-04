//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library CodecLib {
    error InvalidInt128(int256 n);
    error InvalidUInt128(uint256 n);

    modifier validInt128(int256 n) {
        if (n > type(int128).max || n < type(int128).min) {
            revert InvalidInt128(n);
        }
        _;
    }

    modifier validUInt128(uint256 n) {
        if (n > type(uint128).max) {
            revert InvalidUInt128(n);
        }
        _;
    }

    function encodeU128(uint256 a, uint256 b) internal pure validUInt128(a) validUInt128(b) returns (uint256 encoded) {
        encoded |= uint256(uint128(a)) << 128;
        encoded |= uint256(uint128(b));
    }

    function decodeU128(uint256 encoded) internal pure returns (uint128 a, uint128 b) {
        a = uint128(encoded >> 128);
        b = uint128(encoded);
    }

    function encodeI128(int256 a, int256 b) internal pure validInt128(a) validInt128(b) returns (uint256 encoded) {
        encoded |= uint256(uint128(int128(a))) << 128;
        encoded |= uint256(uint128(int128(b)));
    }

    function decodeI128(uint256 encoded) internal pure returns (int128 a, int128 b) {
        a = int128(uint128(encoded >> 128));
        b = int128(uint128(encoded));
    }
}