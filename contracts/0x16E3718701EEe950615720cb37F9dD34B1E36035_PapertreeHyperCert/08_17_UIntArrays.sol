// utils/UIntArrays.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "hardhat/console.sol";


library UIntArrays {

    function sum(uint256[] memory self) public pure returns (uint256) {
        uint256 sum_;
        for (uint256 i = 0; i < self.length; ++i) {
            sum_ += self[i];
        }
        return sum_;
    }

    function isSameList(uint256[] memory self, uint256[] memory arr2) public view returns (bool) {
        return keccak256(abi.encodePacked(sort(self))) == keccak256(abi.encodePacked(sort(arr2)));
    }

    function sort(uint256[] memory self) public view returns(uint256[] memory) {
        if(self.length == 0) return self;
        quickSort(self, int(0), int(self.length - 1));
        return self;
    }
    
    function quickSort(uint256[] memory arr, int left, int right) public view {
        int i = left; //0
        int j = right; //2
        if(i==j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)]; // arr[1] == 2
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++; // i == 1
            while (pivot < arr[uint256(j)]) j--; // j == 1
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

}