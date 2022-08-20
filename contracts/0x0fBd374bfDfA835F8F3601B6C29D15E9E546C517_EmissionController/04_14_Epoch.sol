// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Operator} from "./Operator.sol";
import {IEpoch} from "../interfaces/IEpoch.sol";

contract Epoch is IEpoch, Operator {
  using SafeMath for uint256;

  uint256 private period;
  uint256 private startTime;
  uint256 private lastExecutedAt;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    uint256 _period,
    uint256 _startTime,
    uint256 _startEpoch
  ) {
    require(_startTime >= block.timestamp, "Epoch: invalid start time");
    period = _period;
    startTime = _startTime;
    lastExecutedAt = startTime.add(_startEpoch.mul(period));
  }

  /* ========== Modifier ========== */

  modifier checkStartTime() {
    require(block.timestamp >= startTime, "Epoch: not started yet");
    _;
  }

  modifier checkEpoch() {
    require(block.timestamp > startTime, "Epoch: not started yet");
    require(_callable(), "Epoch: not allowed");
    _;
    lastExecutedAt = block.timestamp;
  }

  function _getLastEpoch() internal view returns (uint256) {
    return lastExecutedAt.sub(startTime).div(period);
  }

  function _getCurrentEpoch() internal view returns (uint256) {
    return Math.max(startTime, block.timestamp).sub(startTime).div(period);
  }

  function callable() external view override returns (bool) {
    return _callable();
  }

  function _callable() internal view returns (bool) {
    return _getCurrentEpoch() >= _getNextEpoch();
  }

  function _getNextEpoch() internal view returns (uint256) {
    if (startTime == lastExecutedAt) {
      return _getLastEpoch();
    }
    return _getLastEpoch().add(1);
  }

  // epoch
  function getLastEpoch() external view override returns (uint256) {
    return _getLastEpoch();
  }

  function getCurrentEpoch() external view override returns (uint256) {
    return Math.max(startTime, block.timestamp).sub(startTime).div(period);
  }

  function getNextEpoch() external view override returns (uint256) {
    return _getNextEpoch();
  }

  function nextEpochPoint() external view override returns (uint256) {
    return startTime.add(_getNextEpoch().mul(period));
  }

  // params
  function getPeriod() external view override returns (uint256) {
    return period;
  }

  function getStartTime() external view override returns (uint256) {
    return startTime;
  }

  /* ========== GOVERNANCE ========== */

  function setPeriod(uint256 _period) external onlyOperator {
    period = _period;
  }
}