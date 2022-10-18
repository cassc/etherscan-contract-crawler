// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {IPowerSwitch} from "./PowerSwitch.sol";

interface IPowered {
    function isOnline() external view returns (bool status);

    function isOffline() external view returns (bool status);

    function isShutdown() external view returns (bool status);

    function isStarted() external view returns (bool status);

    function getPowerSwitch() external view returns (address powerSwitch);

    function getPowerController()
        external
        view
        returns (address controller);
}

/// @title Powered
/// @notice Helper for calling external PowerSwitch
contract Powered is IPowered {
    /* storage */

    address private _powerSwitch;

    /* errors */

    error Powered_NotOnline();
    error Powered_NotOffline();
    error Powered_IsShutdown();
    error Powered_NotShutdown();
    error Powered_NotStarted();

    /* modifiers */

    modifier onlyOnline() {
        _onlyOnline();
        _;
    }

    modifier onlyOffline() {
        _onlyOffline();
        _;
    }

    modifier notShutdown() {
        _notShutdown();
        _;
    }

    modifier onlyShutdown() {
        _onlyShutdown();
        _;
    }

    modifier hasStarted() {
        _hasStarted();
        _;
    }

    /* initializer */

    function _setPowerSwitch(address powerSwitch) internal {
        _powerSwitch = powerSwitch;
    }

    /* getter functions */

    function isOnline() public view override returns (bool status) {
        return IPowerSwitch(_powerSwitch).isOnline();
    }

    function isOffline() public view override returns (bool status) {
        return IPowerSwitch(_powerSwitch).isOffline();
    }

    function isShutdown() public view override returns (bool status) {
        return IPowerSwitch(_powerSwitch).isShutdown();
    }

    function isStarted() public view override returns (bool status) {
        return IPowerSwitch(_powerSwitch).getStatus() != IPowerSwitch.State.NotStarted;
    }

    function getPowerSwitch()
        public
        view
        override
        returns (address powerSwitch)
    {
        return _powerSwitch;
    }

    function getPowerController()
        public
        view
        override
        returns (address controller)
    {
        return IPowerSwitch(_powerSwitch).getPowerController();
    }

    /* convenience functions */

    function _onlyOnline() private view {
        if (!isOnline()) {
            revert Powered_NotOnline();
        }
    }

    function _onlyOffline() private view {
        if (!isOffline()) {
            revert Powered_NotOffline();
        }
    }

    function _notShutdown() private view {
        if (isShutdown()) {
            revert Powered_IsShutdown();
        }
    }

    function _onlyShutdown() private view {
        if (!isShutdown()) {
            revert Powered_NotShutdown();
        }
    }

    function _hasStarted() private view {
        if (!isStarted()) {
            revert Powered_NotStarted();
        }
    }
}