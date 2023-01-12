// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ISpiritGauge{
  function deposit(uint256) external;
  function depositAll() external;
  function withdraw(uint256) external;
  function withdrawAll() external;
  function getReward() external;
  function balanceOf(address) external view returns(uint256);
  function rewards(address) external view returns(uint256);
  function claimVotingFees() external returns (uint claimed0, uint claimed1);
}