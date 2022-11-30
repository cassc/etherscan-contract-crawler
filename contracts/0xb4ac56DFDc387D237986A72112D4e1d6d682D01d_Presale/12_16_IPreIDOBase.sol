// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import './pre_ido/IPreIDOImmutables.sol';
import './pre_ido/IPreIDOState.sol';
import './pre_ido/IPreIDOEvents.sol';

interface IPreIDOBase is IPreIDOImmutables, IPreIDOState, IPreIDOEvents {

}