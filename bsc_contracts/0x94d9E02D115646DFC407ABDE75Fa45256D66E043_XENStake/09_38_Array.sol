// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Array {
    function idx(uint256[] memory arr, uint256 item) internal pure returns (uint256 i) {
        for (i = 1; i <= arr.length; i++) {
            if (arr[i - 1] == item) {
                return i;
            }
        }
        i = 0;
    }

    function addItem(uint256[] storage arr, uint256 item) internal {
        if (idx(arr, item) == 0) {
            arr.push(item);
        }
    }

    function removeItem(uint256[] storage arr, uint256 item) internal {
        uint256 i = idx(arr, item);
        if (i > 0) {
            arr[i - 1] = arr[arr.length - 1];
            arr.pop();
        }
    }

    function contains(uint256[] memory container, uint256[] memory items) internal pure returns (bool) {
        if (items.length == 0) return true;
        for (uint256 i = 0; i < items.length; i++) {
            bool itemIsContained = false;
            for (uint256 j = 0; j < container.length; j++) {
                itemIsContained = items[i] == container[j];
            }
            if (!itemIsContained) return false;
        }
        return true;
    }

    function asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    function hasDuplicatesOrZeros(uint256[] memory array) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == 0) return true;
            for (uint256 j = 0; j < array.length; j++) {
                if (array[i] == array[j] && i != j) return true;
            }
        }
        return false;
    }

    function hasRoguesOrZeros(uint256[] memory array) internal pure returns (bool) {
        uint256 _first = array[0];
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == 0 || array[i] != _first) return true;
        }
        return false;
    }
}