// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IAaveIncentivesVaultImplWithInitialize {
  function initialize(
    address aave,
    address stakedAave,
    uint256 initialStakingDistribution
  ) external;
}