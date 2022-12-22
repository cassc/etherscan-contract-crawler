// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAssets {
  function getAsset(string calldata _name) external view returns (string memory);
}