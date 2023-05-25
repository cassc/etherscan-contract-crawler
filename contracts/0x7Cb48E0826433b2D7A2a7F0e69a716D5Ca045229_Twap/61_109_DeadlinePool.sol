// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../BasePool.sol";
import "../../lib/Windowed.sol";

/**
 * @notice Only allow staking before the deadline.
 */
abstract contract DeadlinePool is BasePool, Windowed {
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration,
    uint256 _startWindow,
    uint256 _endWindow
  )
    BasePool(
      _admin,
      _rewardDistribution,
      _rewardToken,
      _stakingToken,
      _duration
    )
    Windowed(_startWindow, _endWindow)
  {}

  function _beforeStake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual override(BasePool) inWindow {
    super._beforeStake(staker, recipient, amount);
  }
}