// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface to the Pool Factory
 */
interface IPoolFactory {
    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Unsupported Pool implementation
     */
    error UnsupportedImplementation();

    /**
     * @notice Invalid Pool
     */
    error InvalidPool();

    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted when a pool is created
     * @param pool Pool instance
     * @param implementation Implementation contract
     */
    event PoolCreated(address indexed pool, address indexed implementation);

    /**
     * @notice Emitted when a pool implementation is added to allowlist
     * @param implementation Implementation contract
     */
    event PoolImplementationAdded(address indexed implementation);

    /**
     * @notice Emitted when a pool implementation is removed from allowlist
     * @param implementation Implementation contract
     */
    event PoolImplementationRemoved(address indexed implementation);

    /**************************************************************************/
    /* API */
    /**************************************************************************/

    /**
     * Create a pool (immutable)
     * @param poolImplementation Pool implementation contract
     * @param params Pool parameters
     * @return Pool address
     */
    function create(address poolImplementation, bytes calldata params) external returns (address);

    /**
     * Create a pool (proxied)
     * @param poolBeacon Pool beacon contract
     * @param params Pool parameters
     * @return Pool address
     */
    function createProxied(address poolBeacon, bytes calldata params) external returns (address);

    /**
     * @notice Check if address is a pool
     * @param pool Pool address
     * @return True if address is a pool, otherwise false
     */
    function isPool(address pool) external view returns (bool);

    /**
     * @notice Get list of pools
     * @return List of pool addresses
     */
    function getPools() external view returns (address[] memory);

    /**
     * @notice Get count of pools
     * @return Count of pools
     */
    function getPoolCount() external view returns (uint256);

    /**
     * @notice Get pool at index
     * @param index Index
     * @return Pool address
     */
    function getPoolAt(uint256 index) external view returns (address);

    /**
     * @notice Get list of supported pool implementations
     * @return List of pool implementations
     */
    function getPoolImplementations() external view returns (address[] memory);
}