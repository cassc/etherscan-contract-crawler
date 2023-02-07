// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IGovernable} from '../interfaces/IGovernable.sol';

/// @title Governable contract
/// @notice Manages the governor role
abstract contract Governable is IGovernable {
    /// @inheritdoc IGovernable
    address public governor;

    /// @inheritdoc IGovernable
    address public pendingGovernor;

    constructor(address _governor) {
        if (_governor == address(0)) revert ZeroAddress();
        governor = _governor;
    }

    /// @inheritdoc IGovernable
    function setPendingGovernor(address _pendingGovernor) external onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    /// @inheritdoc IGovernable
    function acceptPendingGovernor() external onlyPendingGovernor {
        _acceptPendingGovernor();
    }

    function _setPendingGovernor(address _pendingGovernor) internal {
        if (_pendingGovernor == address(0)) revert ZeroAddress();
        pendingGovernor = _pendingGovernor;
        emit PendingGovernorSet(governor, _pendingGovernor);
    }

    function _acceptPendingGovernor() internal {
        governor = pendingGovernor;
        delete pendingGovernor;
        emit PendingGovernorAccepted(governor);
    }

    /// @notice Functions with this modifier can only be called by governor
    modifier onlyGovernor() {
        if (msg.sender != governor) revert OnlyGovernor();
        _;
    }

    /// @notice Functions with this modifier can only be called by pendingGovernor
    modifier onlyPendingGovernor() {
        if (msg.sender != pendingGovernor) revert OnlyPendingGovernor();
        _;
    }
}