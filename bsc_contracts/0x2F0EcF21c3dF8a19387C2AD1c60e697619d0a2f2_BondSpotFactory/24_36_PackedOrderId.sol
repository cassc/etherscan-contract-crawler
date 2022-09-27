// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "hardhat/console.sol";

/// @dev Helper library for packing and unpacking Pair limit order IDs.
library PackedOrderId {
    /// @dev Packs a pair limit order ID.
    function pack(
        uint128 _pip,
        uint64 _orderIdx,
        bool _isBuy
    ) internal pure returns (bytes32) {
        return bytes32(_pack64And128AndBool(_pip, _orderIdx, _isBuy));
    }

    /// @dev Unpacks a pair limit order ID.
    function unpack(bytes32 _packed)
        internal
        pure
        returns (
            uint128 _pip,
            uint64 _orderIdx,
            bool isBuy
        )
    {
        return _unpack192(uint256(_packed));
    }

    function isBuy(bytes32 _packed) internal view returns (bool isBuy) {
        return _unpackSide(uint256(_packed));
    }

    function _pack64And128(uint128 a, uint64 b) private pure returns (uint192) {
        // convert to uint192, then shift b (uint64) 128 bits to the left,
        // leave 128 bits in the right and then add a (uint128)
        return (uint192(b) << 128) | uint192(a);
    }

    function _pack64And128AndBool(
        uint128 a,
        uint64 b,
        bool isBuy
    ) private pure returns (uint256) {
        // convert to int256, then shift b (uint64) 128 bits to the left,
        // leave 128 bits in the right and then add a (uint128)
        return (((uint256(b) << 128) | uint256(a)) << 1) | (isBuy ? 1 : 0);
    }

    function _unpack192(uint256 packedN)
        private
        pure
        returns (
            uint128 a,
            uint64 b,
            bool isBuy
        )
    {
        a = uint128(packedN >> 1);
        b = uint64(packedN >> 129);

        if (packedN & 1 == 1) {
            isBuy = true;
        }
    }

    function _unpackSide(uint256 _packed) private view returns (bool) {
        return _packed & 1 == 1 ? true : false;
    }
}