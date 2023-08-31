// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapFactoryErrors {
    /**
     * @notice The given token addresses are the same
     */
    error TokenIdenticalAddress();

    /**
     * @notice The given token address is the zero address
     */
    error TokenZeroAddress();

    /**
     * @notice The given tokens already have a {ButtonswapPair} instance
     */
    error PairExists();

    /**
     * @notice User does not have permission for the attempted operation
     */
    error Forbidden();

    /**
     * @notice There was an attempt to update a parameter to an invalid value
     */
    error InvalidParameter();
}