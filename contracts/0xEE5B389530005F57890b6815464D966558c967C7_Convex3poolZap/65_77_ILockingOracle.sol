// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {IOracleAdapter} from "./IOracleAdapter.sol";

/**
 * @notice For an `IOracleAdapter` that can be locked and unlocked
 */
interface ILockingOracle is IOracleAdapter {
    /// @notice Event fired when using the default lock
    event DefaultLocked(address locker, uint256 defaultPeriod, uint256 lockEnd);

    /// @notice Event fired when using a specified lock period
    event Locked(address locker, uint256 activePeriod, uint256 lockEnd);

    /// @notice Event fired when changing the default locking period
    event DefaultLockPeriodChanged(uint256 newPeriod);

    /// @notice Event fired when unlocking the adapter
    event Unlocked();

    /// @notice Event fired when updating the threshold for stale data
    event ChainlinkStalePeriodUpdated(uint256 period);

    /// @notice Block price/value retrieval for the default locking duration
    function lock() external;

    /**
     * @notice Block price/value retrieval for the specified duration.
     * @param period number of blocks to block retrieving values
     */
    function lockFor(uint256 period) external;

    /**
     * @notice Unblock price/value retrieval.  Should only be callable
     * by the Emergency Safe.
     */
    function emergencyUnlock() external;

    /**
     * @notice Set the length of time before values can be retrieved.
     * @param newPeriod number of blocks before values can be retrieved
     */
    function setDefaultLockPeriod(uint256 newPeriod) external;

    /**
     * @notice Set the length of time before an agg value is considered stale.
     * @param chainlinkStalePeriod_ the length of time in seconds
     */
    function setChainlinkStalePeriod(uint256 chainlinkStalePeriod_) external;

    /**
     * @notice Get the length of time, in number of blocks, before values
     * can be retrieved.
     */
    function defaultLockPeriod() external returns (uint256 period);

    /// @notice Check if the adapter is blocked from retrieving values.
    function isLocked() external view returns (bool);
}