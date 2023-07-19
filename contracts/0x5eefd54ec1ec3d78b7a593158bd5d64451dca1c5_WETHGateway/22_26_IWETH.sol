// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function balanceOf(address guy) external returns (uint256);

  function allowance(address owner, address spender) external returns (uint256);

  function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}