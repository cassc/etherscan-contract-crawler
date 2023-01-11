// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "hardhat/console.sol";

library UintArray {
    function concat(uint[] memory self, uint[] memory array) internal pure returns (uint[] memory) {
        uint[] memory newArray = new uint[](self.length + array.length);
        for (uint i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        for (uint i = 0; i < array.length; i++) {
            newArray[i + self.length] = array[i];
        }
        return newArray;
    }

    function append(uint[] memory self, uint element) internal pure returns (uint[] memory) {
        uint[] memory newArray = new uint[](self.length + 1);
        for (uint i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        newArray[self.length] = element;
        return newArray;
    }

    function remove(uint[] memory self, uint index) internal pure returns (uint[] memory newArray) {
        newArray = new uint[](self.length - 1);
        uint elementsAdded;
        for (uint i = 0; i < self.length; i++) {
            if (i != index) {
                newArray[elementsAdded] = self[i];
                elementsAdded += 1;
            }
        }
        return newArray;
    }

    function sum(uint[] memory self) internal pure returns (uint) {
        uint total;
        for (uint i = 0; i < self.length; i++) {
            total += self[i];
        }
        return total;
    }

    function scale(uint[] memory self, uint newTotal) internal pure returns (uint[] memory) {
        uint totalRatios;
        for (uint i = 0; i < self.length; i++) {
            totalRatios += self[i];
        }
        for (uint i = 0; i < self.length; i++) {
            self[i] = (self[i] * newTotal) / totalRatios;
        }
        return self;
    }

    function insert(uint[] memory self, uint idx, uint value) internal pure returns (uint[] memory newArray) {
        newArray = new uint[](self.length + 1);
        for (uint i = 0; i < idx; i++) {
            newArray[i] = self[i];
        }
        newArray[idx] = value;
        for (uint i = idx; i < self.length; i++) {
            newArray[i + 1] = self[i];
        }
    }

    function copy(uint[] memory self) internal pure returns (uint[] memory copied) {
        copied = new uint[](self.length);
        for (uint i = 0; i < self.length; i++) {
            copied[i] = self[i];
        }
    }

    function slice(uint[] memory self, uint start, uint end) internal pure returns (uint[] memory sliced) {
        sliced = new uint[](end - start);
        uint elementsAdded = 0;
        for (uint i = start; i < end; i++) {
            sliced[elementsAdded] = self[i];
            elementsAdded += 1;
        }
    }

    function log(uint[] memory self) internal view {
        console.log("-------------------uint array-------------------");
        for (uint i = 0; i < self.length; i++) {
            console.log(i, self[i]);
        }
    }
}