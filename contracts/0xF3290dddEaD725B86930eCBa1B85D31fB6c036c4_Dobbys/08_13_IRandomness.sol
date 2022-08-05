// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.7;

interface IRandomness {
  	function getRandom(uint256 seed) external view returns (uint256);
}