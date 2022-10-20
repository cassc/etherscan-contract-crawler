// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./lib/WadRayMath.sol";
import "./storage/PoolRegistryStorage.sol";
import "./interfaces/IPool.sol";
import "./utils/Pauseable.sol";

/**
 * @title PoolRegistry contract
 */
contract PoolRegistry is ReentrancyGuard, Pauseable, PoolRegistryStorageV1 {
    using WadRayMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant VERSION = "1.0.0";

    /// @notice Emitted when fee collector is updated
    event FeeCollectorUpdated(address indexed oldFeeCollector, address indexed newFeeCollector);

    /// @notice Emitted when master oracle contract is updated
    event MasterOracleUpdated(IMasterOracle indexed oldOracle, IMasterOracle indexed newOracle);

    /// @notice Emitted when a pool is registered
    event PoolRegistered(address pool);

    /// @notice Emitted when a pool is unregistered
    event PoolUnregistered(address pool);

    function initialize(IMasterOracle masterOracle_, address feeCollector_) external initializer {
        require(address(masterOracle_) != address(0), "oracle-is-null");
        require(feeCollector_ != address(0), "fee-collector-is-null");

        __ReentrancyGuard_init();
        __Pauseable_init();

        masterOracle = masterOracle_;
        feeCollector = feeCollector_;
    }

    /**
     * @notice Get all pools
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getPools() external view returns (address[] memory) {
        return pools.values();
    }

    /**
     * @notice Check if pool is registered
     * @param pool_ Pool to check
     * @return true if exists
     */
    function poolExists(address pool_) external view returns (bool) {
        return pools.contains(pool_);
    }

    /**
     * @notice Register pool
     */
    function registerPool(address pool_) external onlyGovernor {
        require(pool_ != address(0), "address-is-null");
        require(pools.add(pool_), "already-registered");
        emit PoolRegistered(pool_);
    }

    /**
     * @notice Unregister pool
     */
    function unregisterPool(address pool_) external onlyGovernor {
        require(pools.remove(pool_), "not-registered");
        emit PoolUnregistered(pool_);
    }

    /**
     * @notice Update fee collector
     */
    function updateFeeCollector(address newFeeCollector_) external onlyGovernor {
        require(newFeeCollector_ != address(0), "fee-collector-is-null");
        address _currentFeeCollector = feeCollector;
        require(newFeeCollector_ != _currentFeeCollector, "new-same-as-current");
        emit FeeCollectorUpdated(_currentFeeCollector, newFeeCollector_);
        feeCollector = newFeeCollector_;
    }

    /**
     * @notice Update master oracle contract
     */
    function updateMasterOracle(IMasterOracle newMasterOracle_) external override onlyGovernor {
        require(address(newMasterOracle_) != address(0), "address-is-null");
        IMasterOracle _currentMasterOracle = masterOracle;
        require(newMasterOracle_ != _currentMasterOracle, "new-same-as-current");
        emit MasterOracleUpdated(_currentMasterOracle, newMasterOracle_);
        masterOracle = newMasterOracle_;
    }
}