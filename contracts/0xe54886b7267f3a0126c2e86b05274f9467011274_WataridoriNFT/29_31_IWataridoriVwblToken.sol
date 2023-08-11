// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWataridoriVwblToken {
  function getTokenCounter() external view returns (uint256);
  function getAdditionalCheckAddress() external view returns (address);
}