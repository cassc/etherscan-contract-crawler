// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library MergeHelper {
    using Strings for uint256;

    function quickSort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    function sortArray(uint256[] memory arr) internal pure returns (uint256[] memory) {
        quickSort(arr, int256(0), int256(arr.length - 1));
        return arr;
    }

    function generateMergeSet(uint256[] memory _tokenIds) internal pure returns (string memory) {
        require(_tokenIds.length > 0, "MergeHelper: Empty tokenIds");
        uint256[] memory sortedTokenIds = sortArray(_tokenIds);
        for (uint256 i = 0; i < sortedTokenIds.length - 1; i++) {
            require(sortedTokenIds[i] != sortedTokenIds[i + 1], "MergeHelper: Duplicate tokenIds");
        }
        string memory mergeSet = "";
        for (uint256 i = 0; i < sortedTokenIds.length; i++) {
            if (i != 0) {
                mergeSet = string(abi.encodePacked(mergeSet, "-"));
            }
            mergeSet = string(abi.encodePacked(mergeSet, _tokenIds[i].toString()));
        }
        return mergeSet;
    }
}