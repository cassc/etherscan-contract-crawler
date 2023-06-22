// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IHegicPoolV3LotManager {
  event RewardsClaimed(uint256 rewards);
  event LotsBought(uint256 eth, uint256 wbtc);
  function claimRewards() external returns (uint rewards);
  function buyLots(uint256 eth, uint256 wbtc) external returns (bool);
}