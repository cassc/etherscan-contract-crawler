// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

library StringArray {
    function concat(string[] memory self, string[] memory array) internal pure returns (string[] memory) {
        string[] memory newArray = new string[](self.length + array.length);
        for (uint i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        for (uint i = 0; i < array.length; i++) {
            newArray[i + self.length] = array[i];
        }
        return newArray;
    }

    function append(string[] memory self, string memory element) internal pure returns (string[] memory) {
        string[] memory newArray = new string[](self.length + 1);
        for (uint i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        newArray[self.length] = element;
        return newArray;
    }
}