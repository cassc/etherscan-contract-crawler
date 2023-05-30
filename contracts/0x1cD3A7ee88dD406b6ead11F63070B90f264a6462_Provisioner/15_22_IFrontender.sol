// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


interface IFrontender
{
  function isRegistered (address account) external view returns (bool);

  function refer (address account, uint256 amount, address referrer) external;
}