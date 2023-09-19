// SPDX-License-Identifier: MIT

/// @title Library for Bytes Manipulation
pragma solidity ^0.8.9;

library BytesLib {
    function toAddress(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (address tempAddress) {
        assembly {
            tempAddress := mload(add(add(_bytes, 0x14), _start))
        }
    }

    function toUint24(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint24 amount) {
        assembly {
            amount := mload(add(add(_bytes, 0x3), _start))
        }
    }

    /// @param _bytes The bytes input
    /// @param _start The start index of the slice
    /// @param _length The length of the slice
    function sliceBytes(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory slicedBytes) {
        assembly {
            slicedBytes := mload(0x40)

            let lengthmod := and(_length, 31)

            let mc := add(
                add(slicedBytes, lengthmod),
                mul(0x20, iszero(lengthmod))
            )
            let end := add(mc, _length)

            for {
                let cc := add(
                    add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))),
                    _start
                )
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(slicedBytes, _length)
            mstore(0x40, and(add(mc, 31), not(31)))
        }
        return slicedBytes;
    }
}