// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library Random {
    function rand(uint salt) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, salt)));
    }

    function randFrom(uint[] memory array, uint from, uint to, uint randomValue)
    internal pure returns (uint) {
        uint count = to - from;
        return array[from + randomValue % count];
    }

    function shuffle(uint[] memory array, uint randomValue) internal pure returns (uint[] memory) {
        for (uint i = 0; i < array.length; i++) {
            uint n = i + randomValue % (array.length - i);
            uint temp = array[n];
            array[n] = array[i];
            array[i] = temp;
        }
        return array;
    }
}