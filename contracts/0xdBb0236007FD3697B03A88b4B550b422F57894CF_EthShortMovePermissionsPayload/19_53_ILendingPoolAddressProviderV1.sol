// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ILendingPoolAddressProviderV1 {
  function setLendingPoolManager(address _lendingPoolManager) external;

  function setPriceOracle(address _priceOracle) external;
}