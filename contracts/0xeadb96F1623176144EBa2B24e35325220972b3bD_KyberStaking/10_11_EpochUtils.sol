// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../interfaces/staking/IEpochUtils.sol';

contract EpochUtils is IEpochUtils {
  using SafeMath for uint256;

  uint256 public immutable override epochPeriodInSeconds;
  uint256 public immutable override firstEpochStartTime;

  constructor(uint256 _epochPeriod, uint256 _startTime) {
    require(_epochPeriod > 0, 'ctor: epoch period is 0');

    epochPeriodInSeconds = _epochPeriod;
    firstEpochStartTime = _startTime;
  }

  function getCurrentEpochNumber() public override view returns (uint256) {
    return getEpochNumber(block.timestamp);
  }

  function getEpochNumber(uint256 currentTime) public override view returns (uint256) {
    if (currentTime < firstEpochStartTime || epochPeriodInSeconds == 0) {
      return 0;
    }
    // ((currentTime - firstEpochStartTime) / epochPeriodInSeconds) + 1;
    return ((currentTime.sub(firstEpochStartTime)).div(epochPeriodInSeconds)).add(1);
  }
}