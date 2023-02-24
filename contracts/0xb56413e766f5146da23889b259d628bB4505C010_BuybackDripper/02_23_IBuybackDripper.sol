// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IBuyback.sol";

/**
 * @title Buyback drip Contract
 * @notice Distributes a token to a buyback at a fixed rate.
 * @dev This contract must be poked via the `drip()` function every so often.
 * @author Minterest
 */
interface IBuybackDripper is IAccessControl {
    event PeriodDurationChanged(uint256 duration);
    event PeriodRateChanged(uint256 rate);
    event NewPeriod(uint256 start, uint256 duration, uint256 dripPerHour);

    /**
     * @notice get keccak-256 hash of TIMELOCK role
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of TOKEN_PROVIDER role
     */
    function TOKEN_PROVIDER() external view returns (bytes32);

    /**
     * @notice get duration in hours that will be used at next period start
     */
    function nextPeriodDuration() external view returns (uint256);

    /**
     * @notice get drip rate that will be used at next period start
     */
    function nextPeriodRate() external view returns (uint256);

    /**
     * @notice get timestamp in hours of current period start
     */
    function periodStart() external view returns (uint256);

    /**
     * @notice get duration in hours of current period
     */
    function periodDuration() external view returns (uint256);

    /**
     * @notice get tokens that should go to buyback per hour during current period
     */
    function dripPerHour() external view returns (uint256);

    /**
     * @notice get timestamp in hours when last drip to buyback occurred
     */
    function previousDripTime() external view returns (uint256);

    /**
     * @notice Sets duration for the next period
     * @param duration in hours
     * @dev RESTRICTION: Timelock only
     */
    function setPeriodDuration(uint256 duration) external;

    /**
     * @notice Sets rate for the next period
     * @param rate percents scaled with precision of 1e18. Should be in range (0; 1].
     * @dev RESTRICTION: Timelock only
     */
    function setPeriodRate(uint256 rate) external;

    /**
     * @notice Drips tokens to buyback with defined drip rate. Cannot be called more than once per hour.
     */
    function drip() external;

    /**
     * @notice Transfers MNT from TOKEN_PROVIDER caller and updates total MNT amount available for dripping.
     * @dev RESTRICTION:Token provider only
     */
    function refill(uint256 amount) external;
}