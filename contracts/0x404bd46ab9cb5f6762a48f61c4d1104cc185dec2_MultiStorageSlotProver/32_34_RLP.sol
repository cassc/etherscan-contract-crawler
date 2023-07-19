/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title RLP
 * @author Theori, Inc.
 * @notice Gas optimized RLP parsing code. Note that some parsing logic is
 *         duplicated because helper functions are oddly expensive.
 */
library RLP {
    function parseUint(bytes calldata buf) internal pure returns (uint256 result, uint256 size) {
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a not a long string or list (> 0xB7)
            // also ensure it's not a short string longer than 32 bytes (> 0xA0)
            if gt(kind, 0xA0) {
                revert(0, 0)
            }

            switch lt(kind, 0x80)
            case true {
                // small single byte
                result := kind
                size := 1
            }
            case false {
                // short string
                size := sub(kind, 0x80)

                // ensure it's not reading out of bounds
                if lt(buf.length, size) {
                    revert(0, 0)
                }

                switch eq(size, 32)
                case true {
                    // if it's exactly 32 bytes, read it from calldata
                    result := calldataload(add(buf.offset, 1))
                }
                case false {
                    // if it's < 32 bytes, we've already read it from calldata
                    result := shr(shl(3, sub(32, size)), shl(8, first32))
                }
                size := add(size, 1)
            }
        }
    }

    function nextSize(bytes calldata buf) internal pure returns (uint256 size) {
        assembly {
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            switch lt(kind, 0x80)
            case true {
                // small single byte
                size := 1
            }
            case false {
                switch lt(kind, 0xB8)
                case true {
                    // short string
                    size := add(1, sub(kind, 0x80))
                }
                case false {
                    switch lt(kind, 0xC0)
                    case true {
                        // long string
                        let lengthSize := sub(kind, 0xB7)

                        // ensure that we don't overflow
                        if gt(lengthSize, 31) {
                            revert(0, 0)
                        }

                        // ensure that we don't read out of bounds
                        if lt(buf.length, lengthSize) {
                            revert(0, 0)
                        }
                        size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                        size := add(size, add(1, lengthSize))
                    }
                    case false {
                        switch lt(kind, 0xF8)
                        case true {
                            // short list
                            size := add(1, sub(kind, 0xC0))
                        }
                        case false {
                            let lengthSize := sub(kind, 0xF7)

                            // ensure that we don't overflow
                            if gt(lengthSize, 31) {
                                revert(0, 0)
                            }
                            // ensure that we don't read out of bounds
                            if lt(buf.length, lengthSize) {
                                revert(0, 0)
                            }
                            size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                            size := add(size, add(1, lengthSize))
                        }
                    }
                }
            }
        }
    }

    function skip(bytes calldata buf) internal pure returns (bytes calldata) {
        uint256 size = RLP.nextSize(buf);
        assembly {
            buf.offset := add(buf.offset, size)
            buf.length := sub(buf.length, size)
        }
        return buf;
    }

    function parseList(bytes calldata buf)
        internal
        pure
        returns (uint256 listSize, uint256 offset)
    {
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a list
            if lt(kind, 0xC0) {
                revert(0, 0)
            }

            switch lt(kind, 0xF8)
            case true {
                // short list
                listSize := sub(kind, 0xC0)
                offset := 1
            }
            case false {
                // long list
                let lengthSize := sub(kind, 0xF7)

                // ensure that we don't overflow
                if gt(lengthSize, 31) {
                    revert(0, 0)
                }
                // ensure that we don't read out of bounds
                if lt(buf.length, lengthSize) {
                    revert(0, 0)
                }
                listSize := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                offset := add(lengthSize, 1)
            }
        }
    }

    function splitBytes(bytes calldata buf)
        internal
        pure
        returns (bytes calldata result, bytes calldata rest)
    {
        uint256 offset;
        uint256 size;
        assembly {
            // check that we have at least one byte of input
            if iszero(buf.length) {
                revert(0, 0)
            }
            let first32 := calldataload(buf.offset)
            let kind := shr(248, first32)

            // ensure it's a not list
            if gt(kind, 0xBF) {
                revert(0, 0)
            }

            switch lt(kind, 0x80)
            case true {
                // small single byte
                offset := 0
                size := 1
            }
            case false {
                switch lt(kind, 0xB8)
                case true {
                    // short string
                    offset := 1
                    size := sub(kind, 0x80)
                }
                case false {
                    // long string
                    let lengthSize := sub(kind, 0xB7)

                    // ensure that we don't overflow
                    if gt(lengthSize, 31) {
                        revert(0, 0)
                    }
                    // ensure we don't read out of bounds
                    if lt(buf.length, lengthSize) {
                        revert(0, 0)
                    }
                    size := shr(mul(8, sub(32, lengthSize)), shl(8, first32))
                    offset := add(lengthSize, 1)
                }
            }

            result.offset := add(buf.offset, offset)
            result.length := size

            let end := add(offset, size)
            rest.offset := add(buf.offset, end)
            rest.length := sub(buf.length, end)
        }
    }

    function encodeUint(uint256 value) internal pure returns (bytes memory) {
        // allocate our result bytes
        bytes memory result = new bytes(33);

        if (value == 0) {
            // store length = 1, value = 0x80
            assembly {
                mstore(add(result, 1), 0x180)
            }
            return result;
        }

        if (value < 128) {
            // store length = 1, value = value
            assembly {
                mstore(add(result, 1), or(0x100, value))
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 33, prefix 0xa0 followed by value
            assembly {
                mstore(add(result, 1), 0x21a0)
                mstore(add(result, 33), value)
            }
            return result;
        }

        if (value > 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
            // length 32, prefix 0x9f followed by value
            assembly {
                mstore(add(result, 1), 0x209f)
                mstore(add(result, 33), shl(8, value))
            }
            return result;
        }

        assembly {
            let length := 1
            for {
                let min := 0x100
            } lt(sub(min, 1), value) {
                min := shl(8, min)
            } {
                length := add(length, 1)
            }

            let bytesLength := add(length, 1)

            // bytes length field
            let hi := shl(mul(bytesLength, 8), bytesLength)

            // rlp encoding of value
            let lo := or(shl(mul(length, 8), add(length, 0x80)), value)

            mstore(add(result, bytesLength), or(hi, lo))
        }
        return result;
    }
}