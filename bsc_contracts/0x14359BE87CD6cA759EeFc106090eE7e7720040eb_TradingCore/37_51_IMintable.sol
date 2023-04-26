// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IMintable {
  function balance() external view returns (uint256);

  function addBalance(uint256 amount) external;

  function removeBalance(uint256 amount) external;

  function mint(address to, uint256 amount) external;
}

interface IEmittable {
  function emissions(address claimer) external view returns (uint256);
}