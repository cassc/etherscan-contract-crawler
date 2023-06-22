// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IRandomNumberConsumer { 
    function getRandomNumber(uint) external;
}