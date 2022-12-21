// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISubscriptionsManager {
  enum SubType {
    NORMAL,
    SUPER,
    NONE
  }

  struct SubInfo {
    bool subscribed;
    SubType subType;
    uint256 timestamp;
    bytes subId;
  }

  function isSubscribed(address target) external view returns (bool);

  function subscriptionInfo(
    address target
  ) external view returns (SubInfo memory);
}