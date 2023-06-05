// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ISchedule {
  function periodsPerPrincipalPeriod() external view returns (uint256);

  function periodsInTerm() external view returns (uint256);

  function periodsPerInterestPeriod() external view returns (uint256);

  function gracePrincipalPeriods() external view returns (uint256);

  /**
   * @notice Returns the period that timestamp resides in
   */
  function periodAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the principal period that timestamp resides in
   */
  function principalPeriodAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the interest period that timestamp resides in
   */
  function interestPeriodAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns true if the given timestamp resides in a principal grace period
   */
  function withinPrincipalGracePeriodAt(
    uint256 startTime,
    uint256 timestamp
  ) external view returns (bool);

  /**
   * Returns the next timestamp where either principal or interest will come due following `timestamp`
   */
  function nextDueTimeAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the previous timestamp where either principal or timestamp came due
   */
  function previousDueTimeAt(uint256 startTime, uint256 timestamp) external view returns (uint256);

  /**
   * @notice Returns the previous timestamp where new interest came due
   */
  function previousInterestDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @notice Returns the previous timestamp where new principal came due
   */
  function previousPrincipalDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @notice Returns the total number of principal periods
   */
  function totalPrincipalPeriods() external view returns (uint256);

  /**
   * @notice Returns the total number of interest periods
   */
  function totalInterestPeriods() external view returns (uint256);

  /**
   * @notice Returns the timestamp that the term will end
   */
  function termEndTime(uint256 startTime) external view returns (uint256);

  /**
   * @notice Returns the timestamp that the term began
   */
  function termStartTime(uint256 startTime) external view returns (uint256);

  /**
   * @notice Returns the next time principal will come due, or the termEndTime if there are no more due times
   */
  function nextPrincipalDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @notice Returns the next time interest will come due, or the termEndTime if there are no more due times
   */
  function nextInterestDueTimeAt(
    uint256 startTime,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @notice Returns the end time of the given period.
   */
  function periodEndTime(uint256 startTime, uint256 period) external view returns (uint256);
}