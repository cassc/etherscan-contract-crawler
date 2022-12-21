// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISubscriptions {

  function subscribe(address to) external;

  function isSubscribed(address target) external view returns (bool);

  function subscribers() external view returns (address[] memory);

  function subscriptionId(address target) external view returns (bytes memory);

  function when(address target) external view returns (uint256);
}