pragma solidity 0.8.18;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Tomcat (interfaces/ITomcatLocker.sol)

/**
 * @title Tomcat Launch Locker
 * @notice At the launch vault closing time, this contract will pull the MAV and lock into
 * veMAV.
 */
interface ITomcatLaunchLocker {
    /**
     * @notice Pull the MAV from sender and lock into veMAV
     */
    function lock(uint256 amount) external;
}