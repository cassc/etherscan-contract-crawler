// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 *@title BitMap256 Library
 *@dev A library for storing a bitmap of 256 slots, where each slot is represented by a single bit. This allows for efficient storage and manipulation of large amounts of boolean data.
 */
library BitMap256 {
    /**
     * @dev Struct for holding a 256-bit bitmap.
     */
    struct BitMap {
        uint256 data;
    }

    /**
     *@dev Calculate the index for a given value in the bitmap.
     *@param value_ The value for which the index needs to be calculated.
     *@param shouldHash_ A boolean flag indicating if the value should be hashed.
     *@return idx The calculated index for the given value.
     */
    function index(
        uint256 value_,
        bool shouldHash_
    ) internal pure returns (uint256 idx) {
        assembly {
            if shouldHash_ {
                mstore(0x00, value_)
                value_ := keccak256(0x00, 0x20)
            }
            idx := and(0xff, value_)
        }
    }

    /**
     *@dev Get the value of a bit at a given index in the bitmap.
     *@param bitmap_ The storage bitmap to get the value from.
     *@param value_ The value for which the index needs to be calculated.
     *@param shouldHash_ A boolean flag indicating if the value should be hashed.
     *@return isSet A boolean indicating if the bit at the given index is set.
     */
    function get(
        BitMap storage bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal view returns (bool isSet) {
        assembly {
            if shouldHash_ {
                mstore(0x00, value_)
                value_ := keccak256(0x00, 0x20)
            }
            isSet := and(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
        }
    }

    /**
     *@dev Get the value of a bit at a given index in the bitmap.
     *@param bitmap_ The storage bitmap to get the value from.
     *@param value_ The value for which the index needs to be calculated.
     *@param shouldHash_ A boolean flag indicating if the value should be hashed.
     *@return isSet A boolean indicating if the bit at the given index is set.
     */
    function get(
        uint256 bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal pure returns (bool isSet) {
        assembly {
            if shouldHash_ {
                mstore(0x00, value_)
                value_ := keccak256(0x00, 0x20)
            }
            isSet := and(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    /**
     *@dev Set the data of the storage bitmap to a given value.
     *@param bitmap_ The storage bitmap to set the data of.
     *@param value The value to set the data of the bitmap to.
     */
    function setData(BitMap storage bitmap_, uint256 value) internal {
        assembly {
            sstore(bitmap_.slot, value)
        }
    }

    /**
     *@dev Set or unset the bit at a given index in the bitmap based on the status flag.
     *@param bitmap_ The storage bitmap to set or unset the bit in.
     *@param value_ The value for which the index needs to be calculated.
     *@param shouldHash_ A boolean flag indicating if the value should be hashed.
     *@param status_ A boolean flag indicating if the bit should be set or unset.
     */
    function setTo(
        BitMap storage bitmap_,
        uint256 value_,
        bool shouldHash_,
        bool status_
    ) internal {
        if (status_) set(bitmap_, value_, shouldHash_);
        else unset(bitmap_, value_, shouldHash_);
    }

    /**
     * @dev Sets the bit at the given index in the bitmap to the given value.
     * If `shouldHash_` is `true`, the value is hashed before computing the index.
     * @param bitmap_ The bitmap to set the bit in.
     * @param value_ The value for which the index needs to be calculated.
     * @param shouldHash_ A boolean flag indicating if the value should be hashed.
     */
    function set(
        BitMap storage bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal {
        assembly {
            if shouldHash_ {
                mstore(0x00, value_)
                value_ := keccak256(0, 0x20)
            }
            sstore(
                bitmap_.slot,
                or(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
            )
        }
    }

    /**
     * @dev Sets the bit at the given index in the bitmap to the given value.
     * If `shouldHash_` is `true`, the value is hashed before computing the index.
     * @param bitmap_ The bitmap to set the bit in.
     * @param value_ The value for which the index needs to be calculated.
     * @param shouldHash_ A boolean flag indicating if the value should be hashed.
     */
    function set(
        uint256 bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal pure returns (uint256 bitmap) {
        assembly {
            if shouldHash_ {
                mstore(0x00, value_)
                value_ := keccak256(0x00, 0x20)
            }
            bitmap := or(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    /**
     * @dev Unsets the bit at the given index in the bitmap to the given value.
     * If `shouldHash_` is `true`, the value is hashed before computing the index.
     * @param bitmap_ The bitmap to set the bit in.
     * @param value_ The value for which the index needs to be calculated.
     * @param shouldHash_ A boolean flag indicating if the value should be hashed.
     */
    function unset(
        BitMap storage bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal {
        assembly {
            if shouldHash_ {
                mstore(0x00, value_)
                value_ := keccak256(0x00, 0x20)
            }

            sstore(
                bitmap_.slot,
                and(sload(bitmap_.slot), not(shl(and(value_, 0xff), 1)))
            )
        }
    }

    /**
     * @dev Unsets the bit at the given index in the bitmap to the given value.
     * If `shouldHash_` is `true`, the value is hashed before computing the index.
     * @param bitmap_ The bitmap to set the bit in.
     * @param value_ The value for which the index needs to be calculated.
     * @param shouldHash_ A boolean flag indicating if the value should be hashed.
     */
    function unset(
        uint256 bitmap_,
        uint256 value_,
        bool shouldHash_
    ) internal pure returns (uint256 bitmap) {
        assembly {
            if shouldHash_ {
                mstore(0x00, value_)
                value_ := keccak256(0x00, 32)
            }
            bitmap := and(bitmap_, not(shl(and(value_, 0xff), 1)))
        }
    }
}