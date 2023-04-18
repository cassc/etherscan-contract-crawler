// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERCBurn {
  function burn(uint256 _amount) external;
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external returns (uint256);
}