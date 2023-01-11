// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "hardhat/console.sol";

library AddressArray {
    function concat(address[] memory self, address[] memory array) internal pure returns (address[] memory) {
        address[] memory newArray = new address[](self.length + array.length);
        for (uint i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        for (uint i = 0; i < array.length; i++) {
            newArray[i + self.length] = array[i];
        }
        return newArray;
    }

    function append(address[] memory self, address element) internal pure returns (address[] memory) {
        address[] memory newArray = new address[](self.length + 1);
        for (uint i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        newArray[self.length] = element;
        return newArray;
    }

    function remove(address[] memory self, uint index) internal pure returns (address[] memory newArray) {
        newArray = new address[](self.length - 1);
        uint elementsAdded;
        for (uint i = 0; i < self.length; i++) {
            if (i != index) {
                newArray[elementsAdded] = self[i];
                elementsAdded += 1;
            }
        }
        return newArray;
    }

    function findAll(address[] memory self, address toFind) internal pure returns (uint[] memory) {
        uint[] memory indices;
        uint numMatching;
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == toFind) {
                numMatching += 1;
            }
        }
        if (numMatching == 0) {
            return indices;
        }
        indices = new uint[](numMatching);
        uint numPushed = 0;
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == toFind) {
                indices[numPushed] = i;
                numPushed += 1;
                if (numPushed == numMatching) {
                    return indices;
                }
            }
        }
        return indices;
    }

    function findFirst(address[] memory self, address toFind) internal pure returns (uint) {
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == toFind) {
                return i;
            }
        }
        return self.length;
    }

    function exists(address[] memory self, address toFind) internal pure returns (bool) {
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == toFind) {
                return true;
            }
        }
        return false;
    }

    function shrink(
        address[] memory self,
        uint[] memory amounts
    ) internal pure returns (address[] memory shrunkTokens, uint[] memory shrunkAmounts) {
        uint[] memory toRemove = new uint[](self.length);
        for (uint i = 0; i < self.length; i++) {
            for (uint j = i; j < self.length; j++) {
                if (j > i && self[i] == self[j]) {
                    amounts[i] = amounts[i] + amounts[j];
                    amounts[j] = 0;
                    toRemove[j] = 1;
                }
            }
        }
        uint shrunkSize;
        for (uint i = 0; i < self.length; i++) {
            if (amounts[i] > 0) {
                shrunkSize += 1;
            }
        }
        shrunkTokens = new address[](shrunkSize);
        shrunkAmounts = new uint[](shrunkSize);
        uint tokensAdded;
        for (uint i = 0; i < self.length; i++) {
            if (amounts[i] > 0) {
                shrunkTokens[tokensAdded] = self[i];
                shrunkAmounts[tokensAdded] = amounts[i];
                tokensAdded += 1;
            }
        }
    }

    function equal(address[] memory array1, address[] memory array2) internal pure returns (bool) {
        if (array1.length != array2.length) return false;
        for (uint i = 0; i < array1.length; i++) {
            bool matchFound = false;
            for (uint j = 0; j < array2.length; j++) {
                if (array1[i] == array2[j]) {
                    matchFound = true;
                    break;
                }
            }
            if (!matchFound) {
                return false;
            }
        }
        return true;
    }

    function copy(address[] memory self) internal pure returns (address[] memory copied) {
        copied = new address[](self.length);
        for (uint i = 0; i < self.length; i++) {
            copied[i] = self[i];
        }
    }

    function log(address[] memory self) internal view {
        console.log("-------------------address array-------------------");
        for (uint i = 0; i < self.length; i++) {
            console.log(i, self[i]);
        }
    }
}