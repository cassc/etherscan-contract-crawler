// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

interface IWorldsSharedMarket {
  function getDefaultTakeRate(uint256 worldId) external view returns (uint16 defaultTakeRateInBasisPoints);

  function getPaymentAddress(uint256 worldId) external view returns (address payable paymentAddress);
}