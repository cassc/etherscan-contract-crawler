// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IApeSwapV3PoolImmutables} from './pool/IApeSwapV3PoolImmutables.sol';
import {IApeSwapV3PoolState} from './pool/IApeSwapV3PoolState.sol';
import {IApeSwapV3PoolDerivedState} from './pool/IApeSwapV3PoolDerivedState.sol';
import {IApeSwapV3PoolActions} from './pool/IApeSwapV3PoolActions.sol';
import {IApeSwapV3PoolOwnerActions} from './pool/IApeSwapV3PoolOwnerActions.sol';
import {IApeSwapV3PoolErrors} from './pool/IApeSwapV3PoolErrors.sol';
import {IApeSwapV3PoolEvents} from './pool/IApeSwapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IApeSwapV3Pool is
    IApeSwapV3PoolImmutables,
    IApeSwapV3PoolState,
    IApeSwapV3PoolDerivedState,
    IApeSwapV3PoolActions,
    IApeSwapV3PoolOwnerActions,
    IApeSwapV3PoolErrors,
    IApeSwapV3PoolEvents
{

}