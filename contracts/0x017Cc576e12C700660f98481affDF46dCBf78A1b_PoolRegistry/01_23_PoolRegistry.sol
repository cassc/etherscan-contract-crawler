// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./lib/WadRayMath.sol";
import "./storage/PoolRegistryStorage.sol";
import "./interfaces/IPool.sol";
import "./utils/Pauseable.sol";

error OracleIsNull();
error FeeCollectorIsNull();
error NativeTokenGatewayIsNull();
error AddressIsNull();
error AlreadyRegistered();
error UnregisteredPool();
error NewValueIsSameAsCurrent();

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

    /// @notice Emitted when native token gateway is updated
    event NativeTokenGatewayUpdated(address indexed oldGateway, address indexed newGateway);

    /// @notice Emitted when a pool is registered
    event PoolRegistered(uint256 indexed id, address indexed pool);

    /// @notice Emitted when a pool is unregistered
    event PoolUnregistered(uint256 indexed id, address indexed pool);

    function initialize(IMasterOracle masterOracle_, address feeCollector_) external initializer {
        if (address(masterOracle_) == address(0)) revert OracleIsNull();
        if (feeCollector_ == address(0)) revert FeeCollectorIsNull();

        __ReentrancyGuard_init();
        __Pauseable_init();

        masterOracle = masterOracle_;
        feeCollector = feeCollector_;

        nextPoolId = 1;
    }

    /**
     * @notice Get all pools
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getPools() external view override returns (address[] memory) {
        return pools.values();
    }

    /**
     * @notice Check if pool is registered
     * @param pool_ Pool to check
     * @return true if exists
     */
    function isPoolRegistered(address pool_) external view override returns (bool) {
        return pools.contains(pool_);
    }

    /**
     * @notice Register pool
     */
    function registerPool(address pool_) external override onlyGovernor {
        if (pool_ == address(0)) revert AddressIsNull();
        if (!pools.add(pool_)) revert AlreadyRegistered();
        uint256 _id = idOfPool[pool_];
        if (_id == 0) {
            _id = nextPoolId++;
            idOfPool[pool_] = _id;
        }
        emit PoolRegistered(_id, pool_);
    }

    /**
     * @notice Unregister pool
     */
    function unregisterPool(address pool_) external override onlyGovernor {
        if (!pools.remove(pool_)) revert UnregisteredPool();
        emit PoolUnregistered(idOfPool[pool_], pool_);
    }

    /**
     * @notice Update fee collector
     */
    function updateFeeCollector(address newFeeCollector_) external override onlyGovernor {
        if (newFeeCollector_ == address(0)) revert FeeCollectorIsNull();
        address _currentFeeCollector = feeCollector;
        if (newFeeCollector_ == _currentFeeCollector) revert NewValueIsSameAsCurrent();
        emit FeeCollectorUpdated(_currentFeeCollector, newFeeCollector_);
        feeCollector = newFeeCollector_;
    }

    /**
     * @notice Update master oracle contract
     */
    function updateMasterOracle(IMasterOracle newMasterOracle_) external override onlyGovernor {
        if (address(newMasterOracle_) == address(0)) revert OracleIsNull();
        IMasterOracle _currentMasterOracle = masterOracle;
        if (newMasterOracle_ == _currentMasterOracle) revert NewValueIsSameAsCurrent();
        emit MasterOracleUpdated(_currentMasterOracle, newMasterOracle_);
        masterOracle = newMasterOracle_;
    }

    /**
     * @notice Update native token gateway
     */
    function updateNativeTokenGateway(address newGateway_) external override onlyGovernor {
        if (address(newGateway_) == address(0)) revert NativeTokenGatewayIsNull();
        address _currentGateway = nativeTokenGateway;
        if (newGateway_ == _currentGateway) revert NewValueIsSameAsCurrent();
        emit NativeTokenGatewayUpdated(_currentGateway, newGateway_);
        nativeTokenGateway = newGateway_;
    }
}