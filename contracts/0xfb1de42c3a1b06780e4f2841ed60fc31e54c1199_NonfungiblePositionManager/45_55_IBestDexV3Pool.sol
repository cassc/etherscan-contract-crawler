// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IBestDexV3PoolImmutables.sol';
import './pool/IBestDexV3PoolState.sol';
import './pool/IBestDexV3PoolDerivedState.sol';
import './pool/IBestDexV3PoolActions.sol';
import './pool/IBestDexV3PoolOwnerActions.sol';
import './pool/IBestDexV3PoolEvents.sol';

/// @title The interface for a BestDex V3 Pool
/// @notice A BestDex pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IBestDexV3Pool is
    IBestDexV3PoolImmutables,
    IBestDexV3PoolState,
    IBestDexV3PoolDerivedState,
    IBestDexV3PoolActions,
    IBestDexV3PoolOwnerActions,
    IBestDexV3PoolEvents
{

}