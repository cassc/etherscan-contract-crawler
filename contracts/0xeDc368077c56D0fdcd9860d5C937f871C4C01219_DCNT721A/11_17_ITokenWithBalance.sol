// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenWithBalance {
  function balanceOf(address owner) external
    returns (uint256);
}