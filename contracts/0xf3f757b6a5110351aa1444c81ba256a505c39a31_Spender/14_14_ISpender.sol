// SPDX-License-Identifier: MIT
// From https://etherscan.io/address/0x216B4B4Ba9F3e719726886d34a177484278Bfcae#code
pragma solidity ^0.8.21;

interface ISpender {
  function transferFrom(address token, address from, address to, uint256 amount) external;
}