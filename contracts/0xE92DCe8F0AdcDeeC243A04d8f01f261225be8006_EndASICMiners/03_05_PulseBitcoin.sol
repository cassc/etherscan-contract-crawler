// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract PulseBitcoin {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event MinerEnd(uint256 data0, uint256 data1, address indexed accountant, uint40 indexed minerId);

  error MinerListEmpty();
  error InvalidMinerIndex(uint256 sentIndex, uint256 lastIndex);
  error InvalidMinerId(uint256 sentId, uint256 expectedId);
  error CannotEndMinerEarly(uint256 servedDays, uint256 requiredDays);

  function minerEnd(uint256 minerIndex, uint256 minerId, address minerAddr) public virtual;
  function currentDay() public virtual view returns (uint256);

  function balanceOf(address account) public view virtual returns (uint256);
  function transfer(address to, uint256 amount) public virtual returns (bool);
}