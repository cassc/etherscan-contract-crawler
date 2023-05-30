pragma solidity ^0.8.0;
/**
 * @title VOLTAGE accumulator contract
 * @dev ERC20
 */

 /**
 *  SPDX-License-Identifier: UNLICENSED
 */

/*
  \ \
   \ \
  __\ \
  \  __\
$VOLT Accumulator'
  \  __\
   \ \
    \ \
     \/   
 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoltageAccumulator is Ownable{
  using SafeERC20 for IERC20;

  uint256 public START;

  mapping(address => uint256) public rates;
  mapping(address => uint256) public rewards;
  mapping(address => uint256) public lastUpdate;

  // keep track of releases for transparency
  uint256 private totalReleased;
  mapping(address => uint256) private released;

  bool stopRewards = false;

  address internal rewardToken = 0xfFbF315f70E458e49229654DeA4cE192d26f9b25;

  function claimReward() external {
    if(stopRewards) revert('Rewards for this contract have been stopped');

    rewards[msg.sender] += getPendingReward(msg.sender);

    IERC20(rewardToken).safeTransfer(msg.sender, rewards[msg.sender]);

    released[msg.sender] += rewards[msg.sender];
    totalReleased += rewards[msg.sender];

    rewards[msg.sender] = 0;
    lastUpdate[msg.sender] = block.timestamp;
  }

  function getTotalClaimable(address user) external view returns(uint256) {
    return rewards[user] + getPendingReward(user);
  }

  function getPendingReward(address user) internal view returns(uint256) {
    return rates[user] * (block.timestamp - lastUpdate[user]);
  }

  function changeRate(address user, uint256 rate) public onlyOwner {
    rewards[user] += getPendingReward(user);
    rates[user] = rate;
    lastUpdate[user] = block.timestamp;
  }

  function addRate(address user, uint256 rate) public onlyOwner {
    if(rates[user] != 0) revert('user already exists');
    
    rates[user] = rate;
    lastUpdate[user] = block.timestamp;
  }

  function withdraw(uint256 amount) public onlyOwner {
    IERC20(rewardToken).safeTransfer(msg.sender, amount);
  }

  function flipStopRewards() public onlyOwner {
    stopRewards = !stopRewards;
  }
}