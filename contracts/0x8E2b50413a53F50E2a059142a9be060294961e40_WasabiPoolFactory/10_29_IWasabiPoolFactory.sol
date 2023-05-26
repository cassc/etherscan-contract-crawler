// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Required interface of an WasabiPoolFactory compliant contract.
 */
interface IWasabiPoolFactory {

    /**
     * @dev The States of Pools
     */
    enum PoolState {
        INVALID,
        ACTIVE,
        DISABLED
    }

    /**
     * @dev Emitted when there is a new pool created
     */
    event NewPool(address poolAddress, address indexed nftAddress, address indexed owner);

    /**
     * @dev INVALID/ACTIVE/DISABLE the specified pool.
     */
    function togglePool(address _poolAddress, PoolState _poolState) external;

    /**
     * @dev Checks if the pool for the given address is enabled.
     */
    function isValidPool(address _poolAddress) external view returns(bool);

    /**
     * @dev Returns the PoolState
     */
    function getPoolState(address _poolAddress) external view returns(PoolState);

    /**
     * @dev Returns IWasabiConduit Contract Address.
     */
    function getConduitAddress() external view returns(address);

    /**
     * @dev Returns IWasabiFeeManager Contract Address.
     */
    function getFeeManager() external view returns(address);
}