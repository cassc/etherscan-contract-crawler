// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import {ISchedule} from "../../../interfaces/ISchedule.sol";
// import {console2 as console} from "forge-std/console2.sol";

/// @notice Convenience struct for passing startTime to all Schedule methods
struct PaymentSchedule {
  ISchedule schedule;
  uint64 startTime;
}

using PaymentScheduleLogic for PaymentSchedule global;

library PaymentScheduleLogic {
  using PaymentScheduleLogic for PaymentSchedule;

  function startAt(PaymentSchedule storage s, uint256 timestamp) internal {
    assert(s.startTime == 0);
    s.startTime = uint64(timestamp);
  }

  function previousInterestDueTimeAt(
    PaymentSchedule storage s,
    uint256 timestamp
  ) internal view isActiveMod(s) returns (uint256) {
    return s.schedule.previousInterestDueTimeAt(s.startTime, timestamp);
  }

  function nextInterestDueTimeAt(
    PaymentSchedule storage s,
    uint256 timestamp
  ) internal view isActiveMod(s) returns (uint256) {
    return s.schedule.nextInterestDueTimeAt(s.startTime, timestamp);
  }

  function nextPrincipalDueTimeAt(
    PaymentSchedule storage s,
    uint256 timestamp
  ) internal view isActiveMod(s) returns (uint256) {
    return s.schedule.nextPrincipalDueTimeAt(s.startTime, timestamp);
  }

  function principalPeriodAt(
    PaymentSchedule storage s,
    uint256 timestamp
  ) internal view isActiveMod(s) returns (uint256) {
    return s.schedule.principalPeriodAt(s.startTime, timestamp);
  }

  function currentPrincipalPeriod(PaymentSchedule storage s) internal view returns (uint256) {
    return s.principalPeriodAt(block.timestamp);
  }

  function currentPeriod(PaymentSchedule storage s) internal view returns (uint256) {
    return s.periodAt(block.timestamp);
  }

  function periodEndTime(
    PaymentSchedule storage s,
    uint256 period
  ) internal view isActiveMod(s) returns (uint256) {
    return s.schedule.periodEndTime(s.startTime, period);
  }

  function periodAt(
    PaymentSchedule storage s,
    uint timestamp
  ) internal view isActiveMod(s) returns (uint256) {
    return s.schedule.periodAt(s.startTime, timestamp);
  }

  function isActive(PaymentSchedule storage s) internal view returns (bool) {
    return s.startTime != 0;
  }

  function termEndTime(PaymentSchedule storage s) internal view returns (uint256) {
    return s.isActive() ? s.schedule.termEndTime(s.startTime) : 0;
  }

  function termStartTime(PaymentSchedule storage s) internal view returns (uint256) {
    return s.isActive() ? s.schedule.termStartTime(s.startTime) : 0;
  }

  function periodsPerPrincipalPeriod(PaymentSchedule storage s) internal view returns (uint256) {
    return s.schedule.periodsPerPrincipalPeriod();
  }

  function nextDueTimeAt(
    PaymentSchedule storage s,
    uint256 timestamp
  ) internal view returns (uint256) {
    return s.isActive() ? s.schedule.nextDueTimeAt(s.startTime, timestamp) : 0;
  }

  function withinPrincipalGracePeriodAt(
    PaymentSchedule storage s,
    uint256 timestamp
  ) internal view returns (bool) {
    return !s.isActive() || s.schedule.withinPrincipalGracePeriodAt(s.startTime, timestamp);
  }

  modifier isActiveMod(PaymentSchedule storage s) {
    // @dev: NA: not active
    require(s.isActive(), "NA");
    _;
  }
}