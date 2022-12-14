/*
IPoolFactory

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Pool factory interface
 *
 * @notice this defines the Pool factory interface, primarily intended for
 * the Pool contract to interact with
 */
interface IPoolFactory {
    /**
     * @return GYSR treasury address
     */
    function treasury() external view returns (address);

    /**
     * @return GYSR spending fee
     */
    function fee() external view returns (uint256);
}