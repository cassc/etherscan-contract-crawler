// SPDX-License-Identifier: GPL

// Copyright 2022 Fluidity Money. All rights reserved. Use of this
// source code is governed by a GPL-style license that can be found in the
// LICENSE.md file.

pragma solidity ^0.8.11;
pragma abicoder v1;

import "./openzeppelin/IERC20.sol";

/// @title generic interface around an interest source
interface LiquidityProvider {
    /**
     * @notice getter for the owner of the pool (account that can deposit and remove from it)
     * @return address of the owning account
     */
    function owner_() external returns (address);
    /**
     * @notice gets the underlying token (ie, USDt)
     * @return address of the underlying token
     */
    function underlying_() external returns (IERC20);

    /**
     * @notice adds `amount` of tokens to the pool from the amount in the LiquidityProvider
     * @notice requires that the user approve them first
     * @param amount number of tokens to add, in the units of the underlying token
     */
    function addToPool(uint amount) external;
    /**
     * @notice removes `amount` of tokens from the pool
     * @notice sends the tokens to the owner
     * @param amount number of tokens to remove, in the units of the underlying token
     */
    function takeFromPool(uint amount) external;
    /**
     * @notice returns the total amount in the pool, counting the invested amount and the interest earned
     * @return the amount of tokens in the pool, in the units of the underlying token
     */
    function totalPoolAmount() external returns (uint);
}