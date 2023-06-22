//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;

interface IBurnable {
  function burn(uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
}