// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFeeReducer {
  function percentDiscount(address _user)
    external
    view
    returns (uint256, uint256);
}