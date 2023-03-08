// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IWETH9 {
  function withdraw(uint wad) external;

  function transferFrom(
    address src,
    address dst,
    uint wad
  ) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function deposit() external payable;

  function balanceOf(address account) external view returns (uint256);
}