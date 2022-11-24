// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoinFlipBNBRNG {
    
    // returns 1, or 0, randomly. 
    function flipCoin() external view returns (uint256);

    // generates new random number.
    function requestRandomWords(uint256 session) external;
    
}