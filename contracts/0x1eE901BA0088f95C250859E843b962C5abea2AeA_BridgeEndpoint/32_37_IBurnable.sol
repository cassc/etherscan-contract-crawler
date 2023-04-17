// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IBurnable {
  function burn(uint256 amount) external;

  function burnFrom(address from, uint256 amount) external;

  function mint(address to, uint256 amount) external;
}