// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

library UintArray2D {
    function concat(uint[][] memory self, uint[][] memory array) internal pure returns (uint[][] memory) {
        uint[][] memory newArray = new uint[][](self.length + array.length);
        for (uint i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        for (uint i = 0; i < array.length; i++) {
            newArray[i + self.length] = array[i];
        }
        return newArray;
    }

    function append(uint[][] memory self, uint[] memory element) internal pure returns (uint[][] memory) {
        uint[][] memory newArray = new uint[][](self.length + 1);
        for (uint i = 0; i < self.length; i++) {
            newArray[i] = self[i];
        }
        newArray[self.length] = element;
        return newArray;
    }
}