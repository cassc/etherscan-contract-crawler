/**
 * SPDX-License-Identifier: UNLICENSED
 * 
 */
pragma solidity ^0.8.7;

interface Loyalty {
  function addInChunk(address _address, uint256 _amount) external;
}