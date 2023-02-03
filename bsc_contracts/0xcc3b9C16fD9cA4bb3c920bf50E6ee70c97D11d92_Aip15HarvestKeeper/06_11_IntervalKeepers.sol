// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/
pragma solidity 0.8.12;

import { BasicKeepers } from "./BasicKeepers.sol";

// solhint-disable not-rely-on-time
abstract contract IntervalKeepers is BasicKeepers {
  error IntervalKeepers_NotPassInterval();

  uint256 public interval;
  uint256 public lastTimestamp;

  event LogSetInterval(uint256 _prevInterval, uint256 _newInterval);

  constructor(string memory _name, uint256 _interval) BasicKeepers(_name) {
    interval = _interval;
    lastTimestamp = block.timestamp;
  }

  modifier onlyIntervalPassed() {
    if (block.timestamp <= lastTimestamp + interval)
      revert IntervalKeepers_NotPassInterval();
    _;
  }

  function _checkUpkeep(
    bytes calldata /* checkData */
  ) internal view returns (bool, bytes memory) {
    return (block.timestamp > lastTimestamp + interval, "");
  }

  function setInterval(uint256 _newInterval) external onlyOwner {
    uint256 _prevInterval = interval;
    interval = _newInterval;
    emit LogSetInterval(_prevInterval, _newInterval);
  }
}
