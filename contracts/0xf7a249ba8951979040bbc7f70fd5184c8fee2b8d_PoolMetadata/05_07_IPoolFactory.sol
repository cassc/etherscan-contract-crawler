/*
IPoolFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Pool factory interface
 *
 * @notice this defines the Pool factory interface, primarily intended for
 * the Pool contract to interact with
 */
interface IPoolFactory {
    /**
     * @notice create a new Pool
     * @param staking address of factory that will be used to create staking module
     * @param reward address of factory that will be used to create reward module
     * @param stakingdata construction data for staking module factory
     * @param rewarddata construction data for reward module factory
     * @return address of newly created Pool
     */
    function create(
        address staking,
        address reward,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external returns (address);

    /**
     * @return true if address is a pool created by the factory
     */
    function map(address) external view returns (bool);

    /**
     * @return address of the nth pool created by the factory
     */
    function list(uint256) external view returns (address);
}