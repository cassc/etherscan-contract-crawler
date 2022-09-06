// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IOwnable {
  function owner() external view returns (address);

  function admin() external view returns (address);
}