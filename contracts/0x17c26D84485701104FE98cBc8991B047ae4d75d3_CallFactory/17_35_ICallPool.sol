// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "./pool/ICallPoolActions.sol";
import "./pool/ICallPoolDerivedState.sol";
import "./pool/ICallPoolEvents.sol";
import "./pool/ICallPoolImmutables.sol";
import "./pool/ICallPoolOwnerActions.sol";
import "./pool/ICallPoolState.sol";

interface ICallPool is ICallPoolImmutables, ICallPoolActions, ICallPoolDerivedState, ICallPoolEvents, ICallPoolOwnerActions, ICallPoolState{
}