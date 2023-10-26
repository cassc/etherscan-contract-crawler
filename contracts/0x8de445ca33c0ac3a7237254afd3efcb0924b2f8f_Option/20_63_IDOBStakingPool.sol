// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title IDOBStakingPool interface
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev Interface for managing staking pools for DOB options
 */
interface IDOBStakingPool {
    /**
     * @notice Add an option to the staking pool
     * @dev Adds the specified option to the staking pool and associates it with the specified Bullet and Sniper tokens
     * @param _optionAddress The address of the option contract to add
     * @param _bulletAddress The address of the associated BULLET token contract
     * @param _sniperAddress The address of the associated SNIPER token contract
     */
    function addOption(address _optionAddress, address _bulletAddress, address _sniperAddress) external;

    /**
     * @notice Remove an option from the staking pool
     * @dev Removes the specified option from the staking pool
     * @param _optionAddress The address of the option contract to remove
     */
    function removeOption(address _optionAddress) external;
}