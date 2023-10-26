// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './LaunchpadErc20Ido/ILaunchpadErc20IdoActions.sol';
import './LaunchpadErc20Ido/ILaunchpadErc20IdoErrors.sol';
import './LaunchpadErc20Ido/ILaunchpadErc20IdoEvents.sol';
import './LaunchpadErc20Ido/ILaunchpadErc20IdoState.sol';
import './IIdoStorage.sol';


interface ILaunchpadErc20Ido is ILaunchpadErc20IdoActions, ILaunchpadErc20IdoErrors, ILaunchpadErc20IdoEvents, ILaunchpadErc20IdoState {
}