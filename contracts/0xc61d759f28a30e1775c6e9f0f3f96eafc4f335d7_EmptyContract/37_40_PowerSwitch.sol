// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IPowerSwitch {
    /* admin events */

    event PowerOn();
    event PowerOff();
    event EmergencyShutdown();

    /* data types */

    enum State {
        Online,
        Offline,
        Shutdown,
        NotStarted
    }

    /* admin functions */

    function powerOn() external;

    function powerOff() external;

    function emergencyShutdown() external;

    /* view functions */

    function isOnline() external view returns (bool status);

    function isOffline() external view returns (bool status);

    function isShutdown() external view returns (bool status);

    function getStatus() external view returns (State status);

    function getStartTime() external view returns (uint64 startTime);

    function getPowerController()
        external
        view
        returns (address controller);
}

/// @title PowerSwitch
/// @notice Standalone pausing and emergency stop functionality
contract PowerSwitch is IPowerSwitch, Ownable {
    /* storage */

    uint64 private _startTimestamp;
    IPowerSwitch.State private _status;

    error PowerSwitch_CannotPowerOn();
    error PowerSwitch_InvalidOwner();
    error PowerSwitch_CannotPowerOff();
    error PowerSwitch_CannotShutdown();

    /* initializer */

    constructor(address owner, uint64 startTimestamp) {
        // sanity check owner
        if (owner == address(0)) {
            revert PowerSwitch_InvalidOwner();
        }

        _startTimestamp = startTimestamp;
        // transfer ownership
        Ownable.transferOwnership(owner);
    }

    /* admin functions */

    /// @notice Turn Power On
    /// access control: only admin
    /// state machine: only when offline
    /// state scope: only modify _status
    /// token transfer: none
    function powerOn() external override onlyOwner {
        if (_status != IPowerSwitch.State.Offline) {
            revert PowerSwitch_CannotPowerOn();
        }
        _status = IPowerSwitch.State.Online;
        emit PowerOn();
    }

    /// @notice Turn Power Off
    /// access control: only admin
    /// state machine: only when online
    /// state scope: only modify _status
    /// token transfer: none
    function powerOff() external override onlyOwner {
        if (_status != IPowerSwitch.State.Online) {
            revert PowerSwitch_CannotPowerOff();
        }
        _status = IPowerSwitch.State.Offline;
        emit PowerOff();
    }

    /// @notice Shutdown Permanently
    /// access control: only admin
    /// state machine:
    /// - when online or offline
    /// - can only be called once
    /// state scope: only modify _status
    /// token transfer: none
    function emergencyShutdown() external override onlyOwner {
        if (_status == IPowerSwitch.State.Shutdown) {
            revert PowerSwitch_CannotShutdown();
        }
        _status = IPowerSwitch.State.Shutdown;
        emit EmergencyShutdown();
    }

    /* getter functions */

    function isOnline() external view override returns (bool status) {
        return _status == State.Online;
    }

    function isOffline() external view override returns (bool status) {
        return _status == State.Offline;
    }

    function isShutdown() external view override returns (bool status) {
        return _status == State.Shutdown;
    }

    function getStatus()
        external
        view
        override
        returns (IPowerSwitch.State status)
    {
        // if the current timestamp is greater than _startTimestamp or status is not online
        // we return the switch' status
        if (block.timestamp >= uint256(_startTimestamp) || _status != State.Online) {
            return _status;
        } else {
            return State.NotStarted;
        }
    }

    function getStartTime()
        external
        view
        override
        returns (uint64 startTime)
    {
        return _startTimestamp;
    }

    function getPowerController()
        external
        view
        override
        returns (address controller)
    {
        return Ownable.owner();
    }
}