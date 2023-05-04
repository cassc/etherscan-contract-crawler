// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {ISchedule} from "./ISchedule.sol";
import {IPeriodMapper} from "./IPeriodMapper.sol";

interface IMonthlyScheduleRepo {
  function periodMapper() external view returns (IPeriodMapper);

  function getSchedule(
    uint256 periodsInTerm,
    uint256 periodsPerPrincipalPeriod,
    uint256 periodsPerInterestPeriod,
    uint256 gracePrincipalPeriods
  ) external view returns (ISchedule);

  /// @notice Add a schedule with the provided params to the repo
  /// @return schedule the schedule
  function createSchedule(
    uint256 periodsInTerm,
    uint256 periodsPerPrincipalPeriod,
    uint256 periodsPerInterestPeriod,
    uint256 gracePrincipalPeriods
  ) external returns (ISchedule);
}