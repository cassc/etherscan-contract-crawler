//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// interface players have to implement
interface IPlayer {
    // must be the EOA you will be calling the IAmTheOptimizor contract from.
    // this value is to check that no one else is using your code to play.
    function owner() external view returns (address);

    // implement this function and return an array of the 3 indexes (NOT the values)
    // from the inputArr that add up to n.
    // ALL INDEXES MUST BE UNIQUE
    function solve(uint256[10] calldata inputArr, uint256 n)
        external
        returns (uint256[3] calldata);
}