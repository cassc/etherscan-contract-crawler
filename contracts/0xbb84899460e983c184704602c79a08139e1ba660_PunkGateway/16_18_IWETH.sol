// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);

  function balanceOf(address user) external returns (uint256);
}