// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;


struct Snapshot
{
  uint32 epoch;
  uint112 last;
  uint112 cumulative;
}

interface IWUSD
{
  function snapshot () external view returns (Snapshot memory);

  function epochOf (address account) external view returns (uint256);
}