// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IRewardsSchedule {
  event EarlyEndBlockSet(uint256 earlyEndBlock);

  function startBlock() external view returns (uint256);
  function endBlock() external view returns (uint256);
  function getRewardsForBlockRange(uint256 from, uint256 to) external view returns (uint256);
  function setEarlyEndBlock(uint256 earlyEndBlock) external;
}