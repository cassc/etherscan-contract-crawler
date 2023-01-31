//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IAccessControl {
  function isAdmin(address caller) external returns (bool);
}