// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BitMap256} from "./structs/BitMap256.sol";

/**
 *@title ArrayUtil
 *@dev Utility library for working with arrays. This library contains functions for trimming an array and removing duplicate elements from an array by converting it to a set using a bitmap.
 */
library ArrayUtil {
    using BitMap256 for uint256;

    /*
     *@dev Converts an array to a set by removing duplicate elements. Uses a bitmap to store the seen elements for efficiency.
     *@param arr_ The input array to convert to a set.
     *@return An array with the duplicate elements removed.
     */
    function toSet(
        uint256[] memory arr_
    ) internal pure returns (uint256[] memory) {
        uint256 length = arr_.length;
        uint256 seenBitmap;
        uint256 valI;
        unchecked {
            for (uint256 i; i < length; ++i) {
                //  @dev cache element to stack
                valI = arr_[i];

                //  @dev remove dupplicated element by moving it to the end of the array and reduce the length, break the loop only if we found an unseen element (x)
                while (
                    length > i &&
                    seenBitmap.get({value_: valI, shouldHash_: true})
                ) valI = arr_[--length];

                // @dev set seen element in the bitmap and replace dupplicated one with unseen element (x)
                seenBitmap = seenBitmap.set({value_: valI, shouldHash_: true});
                arr_[i] = valI;
            }
        }

        // Shorten the dynamic array by the reduced length.
        assembly {
            mstore(arr_, length)
        }
        return arr_;
    }

    /**
     *@dev Trims an array by removing all elements that match a given value.
     *@param trimVal_ The value to remove from the array.
     *@param arr_ The input array to trim.
     *@return trimmed An array with the specified elements removed.
     */
    function trim(
        uint256[256] storage arr_,
        uint256 trimVal_
    ) internal view returns (uint256[] memory trimmed) {
        trimmed = new uint256[](256);

        uint8 j;
        uint256 valI;
        unchecked {
            for (uint256 i; i < 256; ++i) {
                valI = arr_[i];
                if (valI == trimVal_) continue;

                trimmed[j] = valI;
                ++j;
            }
        }

        // Shorten the `trimmed` dynamic array by new length.
        assembly {
            mstore(trimmed, j)
        }
    }

    /**
     *@dev Trims an array by removing all elements that match a given value.
     *@param trimVal_ The value to remove from the array.
     *@param arr_ The input array to trim.
     *@return trimmed An array with the specified elements removed.
     */
    function trim(
        uint256[] memory arr_,
        uint256 trimVal_
    ) internal pure returns (uint256[] memory trimmed) {
        uint256 length = arr_.length;
        trimmed = new uint256[](length);

        uint256 j;
        uint256 valI;
        unchecked {
            for (uint256 i; i < length; ++i) {
                valI = arr_[i];
                if (valI == trimVal_) continue;

                trimmed[j] = valI;
                ++j;
            }
        }

        // Shorten the `trimmed` dynamic array by new length.
        assembly {
            mstore(trimmed, j)
        }
    }
}