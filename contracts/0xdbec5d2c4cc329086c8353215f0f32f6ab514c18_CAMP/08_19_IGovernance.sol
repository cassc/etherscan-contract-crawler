// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IGovernance { 
    function giveaway() external view returns (address);
    function randomness() external view returns (address);
}