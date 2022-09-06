// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

library CommunityRewardsVesting {
  using SafeMath for uint256;
  using CommunityRewardsVesting for Rewards;

  /// @dev All time values in the Rewards struct (i.e. `startTime`, `endTime`,
  /// `cliffLength`, `vestingInterval`, `revokedAt`) use the same units: seconds. All timestamp
  /// values (i.e. `startTime`, `endTime`, `revokedAt`) are seconds since the unix epoch.
  /// @dev `cliffLength` is the duration from the start of the grant, before which has elapsed
  /// the vested amount remains 0.
  /// @dev `vestingInterval` is the interval at which vesting occurs. If `vestingInterval` is not a
  /// factor of `vestingLength`, rewards are fully vested at the time of the last whole `vestingInterval`.
  struct Rewards {
    uint256 totalGranted;
    uint256 totalClaimed;
    uint256 startTime;
    uint256 endTime;
    uint256 cliffLength;
    uint256 vestingInterval;
    uint256 revokedAt;
  }

  function claim(Rewards storage rewards, uint256 reward) internal {
    rewards.totalClaimed = rewards.totalClaimed.add(reward);
  }

  function claimable(Rewards storage rewards) internal view returns (uint256) {
    return claimable(rewards, block.timestamp);
  }

  function claimable(Rewards storage rewards, uint256 time) internal view returns (uint256) {
    return rewards.totalVestedAt(time).sub(rewards.totalClaimed);
  }

  function totalUnvestedAt(Rewards storage rewards, uint256 time) internal view returns (uint256) {
    return rewards.totalGranted.sub(rewards.totalVestedAt(time));
  }

  function totalVestedAt(Rewards storage rewards, uint256 time) internal view returns (uint256) {
    return
      getTotalVestedAt(
        rewards.startTime,
        rewards.endTime,
        rewards.totalGranted,
        rewards.cliffLength,
        rewards.vestingInterval,
        rewards.revokedAt,
        time
      );
  }

  function getTotalVestedAt(
    uint256 start,
    uint256 end,
    uint256 granted,
    uint256 cliffLength,
    uint256 vestingInterval,
    uint256 revokedAt,
    uint256 time
  ) internal pure returns (uint256) {
    if (time < start.add(cliffLength)) {
      return 0;
    }

    if (end <= start) {
      return granted;
    }

    uint256 elapsedVestingTimestamp = revokedAt > 0 ? Math.min(revokedAt, time) : time;
    uint256 elapsedVestingUnits = (elapsedVestingTimestamp.sub(start)).div(vestingInterval);
    uint256 totalVestingUnits = (end.sub(start)).div(vestingInterval);
    return Math.min(granted.mul(elapsedVestingUnits).div(totalVestingUnits), granted);
  }
}