// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract Asic {
  event Transfer(address indexed from, address indexed to, uint256 value);

  function balanceOf(address account) public view virtual returns (uint256);
  function transfer(address to, uint256 amount) public virtual returns (bool);
}