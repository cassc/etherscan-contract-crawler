// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './LaunchpadNativeIdo/ILaunchpadNativeIdoActions.sol';
import './LaunchpadNativeIdo/ILaunchpadNativeIdoErrors.sol';
import './LaunchpadNativeIdo/ILaunchpadNativeIdoEvents.sol';
import './IIdoStorage.sol';


interface ILaunchpadNativeIdo is ILaunchpadNativeIdoActions, ILaunchpadNativeIdoErrors, ILaunchpadNativeIdoEvents {
}