// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

library StakingRewardsVesting {
  using SafeMath for uint256;
  using StakingRewardsVesting for Rewards;

  uint256 internal constant PERCENTAGE_DECIMALS = 1e18;

  struct Rewards {
    uint256 totalUnvested;
    uint256 totalVested;
    // @dev DEPRECATED (definition kept for storage slot)
    //   For legacy vesting positions, this was used in the case of slashing.
    //   For non-vesting positions, this is unused.
    uint256 totalPreviouslyVested;
    uint256 totalClaimed;
    uint256 startTime;
    // @dev DEPRECATED (definition kept for storage slot)
    //   For legacy vesting positions, this is the endTime of the vesting.
    //   For non-vesting positions, this is 0.
    uint256 endTime;
  }

  function claim(Rewards storage rewards, uint256 reward) internal {
    rewards.totalClaimed = rewards.totalClaimed.add(reward);
  }

  function claimable(Rewards storage rewards) internal view returns (uint256) {
    return rewards.totalVested.add(rewards.totalPreviouslyVested).sub(rewards.totalClaimed);
  }

  function currentGrant(Rewards storage rewards) internal view returns (uint256) {
    return rewards.totalUnvested.add(rewards.totalVested);
  }

  function checkpoint(Rewards storage rewards) internal {
    uint256 newTotalVested = totalVestedAt(rewards.startTime, rewards.endTime, block.timestamp, rewards.currentGrant());

    if (newTotalVested > rewards.totalVested) {
      uint256 difference = newTotalVested.sub(rewards.totalVested);
      rewards.totalUnvested = rewards.totalUnvested.sub(difference);
      rewards.totalVested = newTotalVested;
    }
  }

  function totalVestedAt(
    uint256 start,
    uint256 end,
    uint256 time,
    uint256 grantedAmount
  ) internal pure returns (uint256) {
    if (end <= start) {
      return grantedAmount;
    }

    return Math.min(grantedAmount.mul(time.sub(start)).div(end.sub(start)), grantedAmount);
  }
}