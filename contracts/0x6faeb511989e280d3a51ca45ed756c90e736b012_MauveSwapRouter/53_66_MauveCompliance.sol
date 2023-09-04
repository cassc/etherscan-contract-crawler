// SPDX-License-Identifier: GPL-2.0-or-later
pragma abicoder v2;
pragma solidity =0.7.6;

import '@violetprotocol/mauve-periphery/contracts/base/PeripheryImmutableState.sol';
import '../interfaces/IMauveFactoryReduced.sol';

/// @title MauveCompliance
/// @notice Adds some rules for triggering an EmergencyMode which blocks swaps from happening
abstract contract MauveCompliance is PeripheryImmutableState {
    bool public isEmergencyMode = false;

    modifier onlyFactoryOwner() {
        _checkFactoryOwner();
        _;
    }

    modifier onlyWhenNotEmergencyMode() {
        _checkIsNotInEmergencyMode();
        _;
    }

    function setEmergencyMode(bool isEmergencyMode_) external onlyFactoryOwner {
        isEmergencyMode = isEmergencyMode_;
    }

    function _checkFactoryOwner() internal view {
        address factoryOwner = IMauveFactoryReduced(factory).roles('owner');
        // NFO -> Not Factory Owner
        require(msg.sender == factoryOwner, 'NFO');
    }

    function _checkIsNotInEmergencyMode() internal view {
        // EMA -> Emergency Mode Activated
        // require(!_isEmergencyModeActivated(), 'EMA');
        require(!isEmergencyMode, 'EMA');
    }
}