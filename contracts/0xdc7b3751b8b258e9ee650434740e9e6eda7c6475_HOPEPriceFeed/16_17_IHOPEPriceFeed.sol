// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IHOPEPriceFeed {
  function latestAnswer() external view returns (uint256);
}