// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract IVersion {
  function version() external pure virtual returns (string memory);
}