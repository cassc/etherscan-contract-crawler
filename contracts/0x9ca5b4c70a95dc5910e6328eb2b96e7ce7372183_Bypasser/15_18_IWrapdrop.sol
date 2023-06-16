// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IWrapdrop
{
  function ended () external view returns (bool);

  function round () external view returns (uint256);
}