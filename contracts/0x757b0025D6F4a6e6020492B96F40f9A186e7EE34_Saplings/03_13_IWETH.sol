// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint wad) external;
  function totalSupply() external view returns (uint);
  function approve(address guy, uint wad) external returns (bool);
  function transfer(address dst, uint wad) external returns (bool);
  function transferFrom(address src, address dst, uint wad) external returns (bool);
}