// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;


import "./IUniswapV3PoolDerivedState.sol";
import "./IUniswapV3PoolImmutables.sol";
import "./IUniswapV3PoolState.sol";
import "./IUniswapV3PoolActions.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolImmutables,
    IUniswapV3PoolActions
{

}