// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOKLGFaaSTimePricing {
  function payForPool(uint256 supply, uint256 perBlockAllocation)
    external
    payable;

  function getProductCostWei(uint256 _productCostUSD18)
    external
    view
    returns (uint256);
}