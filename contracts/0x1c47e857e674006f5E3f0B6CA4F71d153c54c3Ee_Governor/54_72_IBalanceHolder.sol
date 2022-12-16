// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.10;

interface IBalanceHolder {
  function withdraw (  ) external;
  function balanceOf ( address ) external view returns ( uint256 );
}