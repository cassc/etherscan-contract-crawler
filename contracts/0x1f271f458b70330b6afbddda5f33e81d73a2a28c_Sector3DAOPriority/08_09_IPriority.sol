// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPriority {

  /**
   * Add a contribution for the current epoch.
   */
  function addContribution(string memory description, string memory proofURL, uint8 hoursSpent, uint8 alignmentPercentage) external;

  /**
   * Claim reward for contributions made in a past epoch.
   */
  function claimReward(uint16 epochNumber) external;
}