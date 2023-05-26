// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface IWETH {
  function deposit() external payable;
  
  function withdraw(uint wad) external;
}