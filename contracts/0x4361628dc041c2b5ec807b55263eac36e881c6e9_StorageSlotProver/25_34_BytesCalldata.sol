/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.13;

// custom bytes calldata pointer storing (length | offset) in one word,
// also allows calldata pointers to be stored in memory
type BytesCalldata is uint256;

using BytesCalldataOps for BytesCalldata global;

// can't introduce global using .. for non UDTs
// each consumer should add the following line:
using BytesCalldataOps for bytes;

/**
 * @author Theori, Inc
 * @title BytesCalldataOps
 * @notice Common operations for bytes calldata, implemented for both the builtin
 *         type and our BytesCalldata type. These operations are heavily optimized
 *         and omit safety checks, so this library should only be used when memory
 *         safety is not a security issue.
 */
library BytesCalldataOps {
    function length(BytesCalldata bc) internal pure returns (uint256 result) {
        assembly {
            result := shr(128, shl(128, bc))
        }
    }

    function offset(BytesCalldata bc) internal pure returns (uint256 result) {
        assembly {
            result := shr(128, bc)
        }
    }

    function convert(BytesCalldata bc) internal pure returns (bytes calldata value) {
        assembly {
            value.offset := shr(128, bc)
            value.length := shr(128, shl(128, bc))
        }
    }

    function convert(bytes calldata inp) internal pure returns (BytesCalldata bc) {
        assembly {
            bc := or(shl(128, inp.offset), inp.length)
        }
    }

    function slice(
        BytesCalldata bc,
        uint256 start,
        uint256 len
    ) internal pure returns (BytesCalldata result) {
        assembly {
            result := shl(128, add(shr(128, bc), start)) // add to the offset and clear the length
            result := or(result, len) // set the new length
        }
    }

    function slice(
        bytes calldata value,
        uint256 start,
        uint256 len
    ) internal pure returns (bytes calldata result) {
        assembly {
            result.offset := add(value.offset, start)
            result.length := len
        }
    }

    function prefix(BytesCalldata bc, uint256 len) internal pure returns (BytesCalldata result) {
        assembly {
            result := shl(128, shr(128, bc)) // clear out the length
            result := or(result, len) // set it to the new length
        }
    }

    function prefix(bytes calldata value, uint256 len)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            result.offset := value.offset
            result.length := len
        }
    }

    function suffix(BytesCalldata bc, uint256 start) internal pure returns (BytesCalldata result) {
        assembly {
            result := add(bc, shl(128, start)) // add to the offset
            result := sub(result, start) // subtract from the length
        }
    }

    function suffix(bytes calldata value, uint256 start)
        internal
        pure
        returns (bytes calldata result)
    {
        assembly {
            result.offset := add(value.offset, start)
            result.length := sub(value.length, start)
        }
    }

    function split(BytesCalldata bc, uint256 start)
        internal
        pure
        returns (BytesCalldata, BytesCalldata)
    {
        return (prefix(bc, start), suffix(bc, start));
    }

    function split(bytes calldata value, uint256 start)
        internal
        pure
        returns (bytes calldata, bytes calldata)
    {
        return (prefix(value, start), suffix(value, start));
    }
}