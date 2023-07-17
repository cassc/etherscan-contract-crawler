// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IAaveTokenImpl {
  function initialize(
    address migrator,
    address distributor,
    address aaveGovernance
  ) external;
}