/*
IPoolInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Pool info interface
 *
 * @notice this defines the Pool info contract interface
 */

interface IPoolInfo {
    /**
     * @notice get information about the underlying staking and reward modules
     * @param pool address of Pool contract
     * @return staking module address
     * @return reward module address
     * @return staking module type
     * @return reward module type
     */
    function modules(
        address pool
    ) external view returns (address, address, address, address);

    /**
     * @notice get pending rewards for arbitrary Pool and user pair
     * @param pool address of Pool contract
     * @param addr address of user for preview
     * @param stakingdata additional data passed to staking module info library
     * @param rewarddata additional data passed to reward module info library
     */
    function rewards(
        address pool,
        address addr,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external view returns (uint256[] memory);
}