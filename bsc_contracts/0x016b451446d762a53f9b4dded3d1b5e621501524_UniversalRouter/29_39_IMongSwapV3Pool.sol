// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IMongSwapV3PoolImmutables.sol';
import './pool/IMongSwapV3PoolState.sol';
import './pool/IMongSwapV3PoolDerivedState.sol';
import './pool/IMongSwapV3PoolActions.sol';
import './pool/IMongSwapV3PoolOwnerActions.sol';
import './pool/IMongSwapV3PoolEvents.sol';

/// @title The interface for a MongSwap V3 Pool
/// @notice A MongSwap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IMongSwapV3Pool is
    IMongSwapV3PoolImmutables,
    IMongSwapV3PoolState,
    IMongSwapV3PoolDerivedState,
    IMongSwapV3PoolActions,
    IMongSwapV3PoolOwnerActions,
    IMongSwapV3PoolEvents
{

}