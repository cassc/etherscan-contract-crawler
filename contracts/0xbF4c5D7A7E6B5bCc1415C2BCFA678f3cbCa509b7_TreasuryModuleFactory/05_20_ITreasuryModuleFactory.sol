//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITreasuryModuleFactory {
  /// @notice Function for initializing the contract that can only be called once
  function initialize(
    ) external;
}