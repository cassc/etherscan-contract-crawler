// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPriceGetter {
  function getPrice() external view returns (uint256 price);
}