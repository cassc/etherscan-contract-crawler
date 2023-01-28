// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFeeReducer {
  function percentDiscount(address wallet)
    external
    view
    returns (uint256, uint256);
}