// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


struct Snapshot
{
  uint32 epoch;
  uint112 last;
  uint112 cumulative;
}

interface IWUSD
{
  function balanceOf (address account) external view returns (uint256);


  function snapshot () external view returns (Snapshot memory);

  function epochOf (address account) external view returns (uint256);


  function allowance (address owner, address spender) external view returns (uint256);

  function approve (address spender, uint256 amount) external returns (bool);


  function transfer (address to, uint256 amount) external returns (bool);

  function transferFrom (address from, address to, uint256 amount ) external returns (bool);
}