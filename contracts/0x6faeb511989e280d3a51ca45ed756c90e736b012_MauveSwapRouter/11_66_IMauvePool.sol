// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IMauvePoolImmutables.sol';
import './pool/IMauvePoolState.sol';
import './pool/IMauvePoolDerivedState.sol';
import './pool/IMauvePoolActions.sol';
import './pool/IMauvePoolOwnerActions.sol';
import './pool/IMauvePoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IMauvePool is
    IMauvePoolImmutables,
    IMauvePoolState,
    IMauvePoolDerivedState,
    IMauvePoolActions,
    IMauvePoolOwnerActions,
    IMauvePoolEvents
{

}