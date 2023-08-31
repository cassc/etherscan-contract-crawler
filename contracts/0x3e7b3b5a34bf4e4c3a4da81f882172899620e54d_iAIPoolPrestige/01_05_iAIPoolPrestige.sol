// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IPool.sol';

contract iAIPoolPrestige is IPool {
  mapping(uint256 => bool) public prestigeIds;

  constructor(address iAITokenAddress, address nftTokenAddress) IPool(iAITokenAddress, nftTokenAddress) {
    poolType = 'Pool Prestige';
    apr = 1000;
    withdrawPenalty = 25;
    nftThreshold = 1;
    tokenThreshold = 200000 ether;
    minPoolPeriod = 365 days;
  }

  function setPrestigeIds(uint256[] memory keys, bool[] memory values) external onlyOwner {
    require(keys.length == values.length, 'Arrays length mismatch');

    for (uint256 i = 0; i < keys.length; i++) {
      prestigeIds[keys[i]] = values[i];
    }
  }

  function determinePrestige(address _address) internal view returns (bool) {
    uint256 totalTokens = nft9022.balanceOf(_address);
    uint256 tokenId;

    for (uint256 i = 0; i < totalTokens; i++) {
      tokenId = nft9022.tokenOfOwnerByIndex(_address, i);
      if (prestigeIds[tokenId]) {
        return true;
      }
    }
    return false;
  }

  function pool(uint256 _amount) external payable {
    require(poolActive, 'Pool is not currently active');
    require(determinePrestige(msg.sender), 'Wallet does not own any Prestige 9022 NFTs');
    require(iAI.balanceOf(msg.sender) >= _amount, 'Insufficient $iAI balance');
    require(_amount >= tokenThreshold, '$iAI threshold not met');

    iAI.transferFrom(msg.sender, address(this), _amount);
    poolBalance[msg.sender] += _amount;
    poolData[msg.sender].push(Pool(_amount, apr, block.timestamp, poolType));
    emit Pooled(msg.sender, _amount);
  }

  function unPool(uint256 _index) external nonReentrant {
    require(poolActive, 'Pool is not currently active');
    require(poolData[msg.sender].length > 0, 'No stakes found for the address');
    require(poolData[msg.sender].length >= _index + 1, 'Stake does not exist');
    // uint256 totalStaked = poolingBalance[msg.sender];
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = poolData[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    require(timeStaked >= minPoolPeriod, 'Minimum pooling period not reached');
    uint256 latestStake = lastStake.amount;
    uint256 reward = (latestStake * apr) / 10000;
    uint256 payout = latestStake + reward;
    // Remove the stake at the given index
    for (uint256 i = _index; i < poolData[msg.sender].length - 1; i++) {
      poolData[msg.sender][i] = poolData[msg.sender][i + 1];
    }
    poolData[msg.sender].pop();
    poolBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, payout);
    emit Unpooled(msg.sender, payout, timeStaked);
  }

  function withdrawPosition(uint256 _index) external nonReentrant {
    require(poolActive, 'Pool is not currently active');
    require(poolData[msg.sender].length > 0, 'No stakes found for the address');
    require(poolData[msg.sender].length >= _index + 1, 'Stake does not exist');
    uint256 lastStakeIndex = _index;
    Pool memory lastStake = poolData[msg.sender][lastStakeIndex];
    uint256 timeStaked = block.timestamp - lastStake.timestamp;
    uint256 latestStake = lastStake.amount;
    require(timeStaked <= minPoolPeriod, 'Withdraw with penalty time exceed you can now unstake token ');
    uint256 penalty = (latestStake * withdrawPenalty) / 100;
    // Remove the stake at the given index
    for (uint256 i = _index; i < poolData[msg.sender].length - 1; i++) {
      poolData[msg.sender][i] = poolData[msg.sender][i + 1];
    }
    poolData[msg.sender].pop();
    poolBalance[msg.sender] -= latestStake;
    lastClaimTime[msg.sender] = block.timestamp;
    uint256 payout = latestStake - penalty;
    iAI.transfer(msg.sender, payout);
    emit Penalty(msg.sender, payout);
  }

  function claimReward() external nonReentrant {
    require(poolActive, 'Pool is not currently active');
    require(poolData[msg.sender].length > 0, 'No stakes found for the address');
    uint256 totalStaked = poolBalance[msg.sender];
    uint256 lastClaim = lastClaimTime[msg.sender];
    uint256 timeElapsed = block.timestamp - lastClaim;
    require(timeElapsed > 0, 'No rewards to claim');
    // Calculate the reward
    uint256 reward = (totalStaked * (apr / 365) * (timeElapsed / 1 days)) / 100;
    require(reward > 0, 'Not Eligible for reward');
    lastClaimTime[msg.sender] = block.timestamp;
    iAI.transfer(msg.sender, reward);
    emit RewardClaimed(msg.sender, reward);
  }
}