// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IStakedAaveImplWithInitialize {
  function initialize(
    address aaveGovernance,
    string calldata name,
    string calldata symbol,
    uint8 decimals
  ) external;
}