// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICbEthRateProvider {
  function exchangeRate() external view returns (uint256);
}