// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IMintable {
  function mint(address to, uint256 amount) external;
}