// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVesting {
  function issue_into_tranche (
    address user,
    uint8 tranche,
    uint256 amount
  ) external;
}