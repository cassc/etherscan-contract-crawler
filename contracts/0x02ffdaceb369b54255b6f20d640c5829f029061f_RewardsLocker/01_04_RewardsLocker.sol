// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IRewardsTracker.sol';

contract RewardsLocker is Ownable {
  IRewardsTracker public rewards;

  constructor(IRewardsTracker _rewards) {
    rewards = _rewards;
  }

  function withdrawRewards() external {
    rewards.claimReward();
    uint256 _bal = address(this).balance;
    require(_bal > 0, 'WITHDRAW: no rewards to withdraw');
    (bool success, ) = payable(owner()).call{ value: _bal }('');
    require(success, 'WITHDRAW: ETH not sent to owner');
  }

  receive() external payable {}
}