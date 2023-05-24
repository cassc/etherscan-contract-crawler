// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ILeverageSwapManager {
  function getLevSwapper(address collateral) external view returns (address);
}