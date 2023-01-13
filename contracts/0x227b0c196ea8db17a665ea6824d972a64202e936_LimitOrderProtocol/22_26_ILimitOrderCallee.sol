// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title Interface for DAI-style permits
interface ILimitOrderCallee {
  function limitOrderCall(
    uint256 makingAmount,
    uint256 takingAmount,
    bytes memory callbackData
  ) external;
}