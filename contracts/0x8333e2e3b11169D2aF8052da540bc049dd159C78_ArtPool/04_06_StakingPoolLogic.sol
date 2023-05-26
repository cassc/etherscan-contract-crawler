// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import '../ArtPool.sol';
import '../libraries/TimeConverter.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library StakingPoolLogic {
  using StakingPoolLogic for ArtPool.PoolData;

  event UpdateStakingPool(
    address indexed user,
    uint256 newRewardIndex,
    uint256 totalPrincipal,
    uint8 currentRound
  );

  function getRewardIndex(ArtPool.PoolData storage poolData) internal view returns (uint256) {
    uint256 currentTimestamp = block.timestamp < poolData.endTimestamp
      ? block.timestamp
      : poolData.endTimestamp;
    uint256 timeDiff = currentTimestamp - poolData.lastUpdateTimestamp;
    uint256 totalPrincipal = poolData.totalPrincipal;

    if (timeDiff == 0) {
      return poolData.rewardIndex;
    }

    if (totalPrincipal == 0) {
      return poolData.rewardIndex;
    }

    uint256 rewardIndexDiff = (timeDiff * poolData.rewardPerSecond * 1e9) / totalPrincipal;

    return poolData.rewardIndex + rewardIndexDiff;
  }

  function getUserReward(ArtPool.PoolData storage poolData, address user)
    internal
    view
    returns (uint256)
  {
    if (poolData.userIndex[user] == 0) {
      return 0;
    }
    uint256 indexDiff = getRewardIndex(poolData) - poolData.userIndex[user];

    uint256 balance = poolData.userPrincipal[user];

    uint256 result = poolData.userReward[user] + (balance * indexDiff) / 1e9;

    return result;
  }

  function updateStakingPool(
    ArtPool.PoolData storage poolData,
    uint8 currentRound,
    address user
  ) internal {
    poolData.userReward[user] = getUserReward(poolData, user);
    poolData.rewardIndex = poolData.userIndex[user] = getRewardIndex(poolData);
    poolData.lastUpdateTimestamp = block.timestamp < poolData.endTimestamp
      ? block.timestamp
      : poolData.endTimestamp;
    emit UpdateStakingPool(msg.sender, poolData.rewardIndex, poolData.totalPrincipal, currentRound);
  }

  function initRound(
    ArtPool.PoolData storage poolData,
    string memory poolName,
    bool isFullLockup,
    uint256 lockupTimestamp,
    uint256 rewardPerSecond,
    uint256 roundStartTimestamp,
    uint8 duration,
    uint256 voteMax
  ) internal returns (uint256, uint256) {
    poolData.poolName = poolName;
    poolData.isFullLockup = isFullLockup;
    poolData.lockupTimestamp = lockupTimestamp;
    poolData.rewardPerSecond = rewardPerSecond;
    poolData.startTimestamp = roundStartTimestamp;
    poolData.endTimestamp = roundStartTimestamp + (duration * 1 days);
    poolData.lastUpdateTimestamp = roundStartTimestamp;
    poolData.rewardIndex = 1e18;
    poolData.whitelistNFT;
    poolData.voteMax = voteMax;

    return (poolData.startTimestamp, poolData.endTimestamp);
  }

  function resetUserData(ArtPool.PoolData storage poolData, address user) internal {
    poolData.userReward[user] = 0;
    poolData.userIndex[user] = 0;
    poolData.userPrincipal[user] = 0;
  }
}