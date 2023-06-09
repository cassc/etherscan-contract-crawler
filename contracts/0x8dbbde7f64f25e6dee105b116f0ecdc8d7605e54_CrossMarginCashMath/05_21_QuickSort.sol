// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IntArrayLib.sol";
import "../UintArrayLib.sol";

/**
 * @author dsshap
 */
library QuickSort {
    /**
     * ----------------------- **
     *  |  Quick Sort For Int256[]  |
     * ----------------------- *
     */

    /**
     * @dev get a new sorted array and index order used to sort.
     * @return y copy of x but sorted
     * @return idxs indexes of input array used for sorting.
     */
    function argSort(int256[] memory x) internal pure returns (int256[] memory y, uint256[] memory idxs) {
        idxs = new uint256[](x.length);
        // fill in index array
        for (uint256 i; i < x.length;) {
            idxs[i] = i;
            unchecked {
                ++i;
            }
        }
        // initialize copy of x
        y = new int256[](x.length);
        IntArrayLib.populate(y, x);
        // sort
        quickSort(y, int256(0), int256(y.length - 1), idxs);
    }

    /**
     * @dev return a new sorted copy of array x
     */
    function getSorted(int256[] memory x) internal pure returns (int256[] memory y) {
        y = new int256[](x.length);
        IntArrayLib.populate(y, x);
        quickSort(y, int256(0), int256(y.length - 1));
    }

    /**
     * @dev sort array x in place with quick sort algorithm
     */
    function sort(int256[] memory x) internal pure {
        quickSort(x, int256(0), int256(x.length - 1));
    }

    /**
     * @dev sort arr[left:right] in place with quick sort algorithm
     */
    function quickSort(int256[] memory arr, int256 left, int256 right) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            int256 pivot = arr[uint256((left + right) / 2)];

            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    /**
     * @dev quicksort implementation with indexes, sorts arr and indexArray in place
     */
    function quickSort(int256[] memory arr, int256 left, int256 right, uint256[] memory indexArray) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            int256 pivot = arr[uint256((left + right) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    (indexArray[uint256(i)], indexArray[uint256(j)]) = (indexArray[uint256(j)], indexArray[uint256(i)]);
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j, indexArray);
        if (i < right) quickSort(arr, i, right, indexArray);
    }

    /**
     * ----------------------- **
     *  |  Quick Sort For Uint256[] |
     * ----------------------- *
     */

    /**
     * @dev get a new sorted array and index order used to sort.
     * @return y copy of x but sorted
     * @return idxs indexes of input array used for sorting.
     */
    function argSort(uint256[] memory x) internal pure returns (uint256[] memory y, uint256[] memory idxs) {
        idxs = new uint256[](x.length);
        // fill in index array
        for (uint256 i; i < x.length;) {
            idxs[i] = i;
            unchecked {
                ++i;
            }
        }
        // initialize copy of x
        y = new uint256[](x.length);
        UintArrayLib.populate(y, x);
        // sort
        quickSort(y, int256(0), int256(y.length - 1), idxs);
    }

    /**
     * @dev return a new sorted copy of array x
     */
    function getSorted(uint256[] memory x) internal pure returns (uint256[] memory y) {
        y = new uint256[](x.length);
        UintArrayLib.populate(y, x);
        quickSort(y, int256(0), int256(y.length - 1));
    }

    /**
     * @dev sort array x in place with quick sort algorithm
     */
    function sort(uint256[] memory x) internal pure {
        quickSort(x, int256(0), int256(x.length - 1));
    }

    /**
     * @dev sort arr[left:right] in place with quick sort algorithm
     */
    function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            uint256 pivot = arr[uint256(left + right) / 2];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    ++i;
                    --j;
                }
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    /**
     * @dev quicksort implementation with indexes, sorts input arr and indexArray IN PLACE
     */
    function quickSort(uint256[] memory arr, int256 left, int256 right, uint256[] memory indexArray) internal pure {
        if (left == right) return;
        int256 i = left;
        int256 j = right;
        unchecked {
            uint256 pivot = arr[uint256((left + right) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) {
                    ++i;
                }
                while (pivot < arr[uint256(j)]) {
                    --j;
                }
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    (indexArray[uint256(i)], indexArray[uint256(j)]) = (indexArray[uint256(j)], indexArray[uint256(i)]);
                    ++i;
                    --j;
                }
            }
            if (left < j) quickSort(arr, left, j, indexArray);
            if (i < right) quickSort(arr, i, right, indexArray);
        }
    }
}