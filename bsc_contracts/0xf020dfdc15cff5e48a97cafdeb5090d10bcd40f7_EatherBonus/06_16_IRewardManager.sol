// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IRewardManager {
  function addPVEReward(uint _mission, address _user, uint _amount, uint[] calldata _heroIds) external returns (uint, bool);
  function getDaysPassed() external view returns (uint);
}