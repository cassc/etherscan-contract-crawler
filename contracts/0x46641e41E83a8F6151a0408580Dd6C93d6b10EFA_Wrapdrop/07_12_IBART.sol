// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IBART
{
  function tokenToStyle (uint256 id) external view returns (uint256);
}