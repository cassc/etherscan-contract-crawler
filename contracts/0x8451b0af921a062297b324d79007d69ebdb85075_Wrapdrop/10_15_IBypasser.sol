// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


struct Pass
{
  uint16 init;
  uint16 last;
  uint128 liquidity;
}

interface IBypasser
{
  function passOf (address account) external view returns (Pass memory);
}