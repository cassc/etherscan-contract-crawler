// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IDropsPriceOracle {
  function convertUsdToWei(uint256 usdAmount) external view returns (uint256 weiAmount);
}