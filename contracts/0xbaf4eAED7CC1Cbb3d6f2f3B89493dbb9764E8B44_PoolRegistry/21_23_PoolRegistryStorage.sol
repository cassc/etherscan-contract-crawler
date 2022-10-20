// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/utils/structs/EnumerableSet.sol";
import "../interfaces/IPoolRegistry.sol";
import "../interfaces/external/IMasterOracle.sol";

abstract contract PoolRegistryStorageV1 is IPoolRegistry {
    /**
     * @notice Pools collection
     */
    EnumerableSet.AddressSet internal pools;

    /**
     * @notice Prices oracle
     */
    IMasterOracle public masterOracle;

    /**
     * @notice Fee collector address
     */
    address public feeCollector;
}