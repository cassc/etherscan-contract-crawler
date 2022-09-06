// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRandomizer {

    function requestRandomWords() external;
    function getRandomWords(uint256 number) external returns (uint256[] memory);
    function getRemainingWords() external view returns (uint256);
    
}