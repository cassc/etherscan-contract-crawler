// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    
    function getRandomWord() external returns (uint256);
    function requestRandomWords() external;
    
}