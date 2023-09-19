// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library CommonLibrary {
    function getContractBytecodeHash(address addr) internal view returns (bytes32 bytecodeHash) {
        assembly {
            bytecodeHash := extcodehash(addr)
        }
    }

    /// @dev returns index of element in array or type(uint32).max if not found
    function binarySearch(address[] calldata array, address element) internal pure returns (uint32 index) {
        uint32 left = 0;
        uint32 right = uint32(array.length);
        uint32 mid;
        while (left + 1 < right) {
            mid = (left + right) >> 1;
            if (array[mid] > element) {
                right = mid;
            } else {
                left = mid;
            }
        }
        if (array[left] != element) {
            return type(uint32).max;
        }
        return left;
    }

    function sort(uint256[] memory array) internal pure returns (uint256[] memory) {
        if (isSorted(array)) return array;
        uint256[] memory sortedArray = array;
        for (uint32 i = 0; i < array.length; i++) {
            for (uint32 j = i + 1; j < array.length; j++) {
                if (sortedArray[i] > sortedArray[j])
                    (sortedArray[i], sortedArray[j]) = (sortedArray[j], sortedArray[i]);
            }
        }
        return sortedArray;
    }

    function isSorted(uint256[] memory array) internal pure returns (bool) {
        for (uint32 i = 0; i + 1 < array.length; i++) {
            if (array[i] > array[i + 1]) return false;
        }
        return true;
    }

    function sort(address[] calldata array) internal pure returns (address[] memory) {
        if (isSorted(array)) return array;
        address[] memory sortedArray = array;
        for (uint32 i = 0; i < array.length; i++) {
            for (uint32 j = i + 1; j < array.length; j++) {
                if (sortedArray[i] > sortedArray[j])
                    (sortedArray[i], sortedArray[j]) = (sortedArray[j], sortedArray[i]);
            }
        }
        return sortedArray;
    }

    function isSorted(address[] calldata array) internal pure returns (bool) {
        for (uint32 i = 0; i + 1 < array.length; i++) {
            if (array[i] > array[i + 1]) return false;
        }
        return true;
    }

    function sortAndMerge(address[] calldata a, address[] calldata b) internal pure returns (address[] memory array) {
        address[] memory sortedA = sort(a);
        address[] memory sortedB = sort(b);
        array = new address[](a.length + b.length);
        uint32 i = 0;
        uint32 j = 0;
        while (i < a.length && j < b.length) {
            if (sortedA[i] < sortedB[j]) {
                array[i + j] = sortedA[i];
                i++;
            } else {
                array[i + j] = sortedB[j];
                j++;
            }
        }
        while (i < a.length) {
            array[i + j] = sortedA[i];
            i++;
        }
        while (j < b.length) {
            array[i + j] = sortedB[j];
            j++;
        }
    }
}