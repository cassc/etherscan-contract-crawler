// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBalancerOwnable {
  function setController(address newOwner) external;

  function getController(address newOwner) external;
}