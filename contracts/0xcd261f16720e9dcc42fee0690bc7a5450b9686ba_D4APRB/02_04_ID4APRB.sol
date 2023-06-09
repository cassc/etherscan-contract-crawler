// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4APRB{
  function isStart() external view returns(bool);
  function currentRound() external view returns(uint256);
}