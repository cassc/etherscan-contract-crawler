// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

interface IWETH {
  function transferFrom(address src, address dst, uint wad) external;
  function deposit() external payable;
  function withdraw(uint wad) external;
  function balanceOf(address user) external view returns (uint256);
  function approve(address guy, uint wad) external returns (bool);
}