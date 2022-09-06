// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface IOwnable {
  function owner() external view returns (address);
}