// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IVeniceswapV3PoolImmutables.sol';
import './pool/IVeniceswapV3PoolState.sol';
import './pool/IVeniceswapV3PoolDerivedState.sol';
import './pool/IVeniceswapV3PoolActions.sol';
import './pool/IVeniceswapV3PoolOwnerActions.sol';
import './pool/IVeniceswapV3PoolEvents.sol';

/// @title The interface for a Veniceswap V3 Pool
/// @notice A Veniceswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IVeniceswapV3Pool is
    IVeniceswapV3PoolImmutables,
    IVeniceswapV3PoolState,
    IVeniceswapV3PoolDerivedState,
    IVeniceswapV3PoolActions,
    IVeniceswapV3PoolOwnerActions,
    IVeniceswapV3PoolEvents
{

}