// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./interfaces/IPoolFactory.sol";

/**
 * @title PoolFactory
 * @author MetaStreet Labs
 */
contract PoolFactory is Ownable, ERC1967Upgrade, IPoolFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.2";

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @notice Initialized boolean
     */
    bool private _initialized;

    /**
     * @notice Set of deployed pools
     */
    EnumerableSet.AddressSet private _pools;

    /**
     * @notice Set of allowed pool implementations
     */
    EnumerableSet.AddressSet private _allowedImplementations;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice PoolFactory constructor
     */
    constructor() {
        /* Disable initialization of implementation contract */
        _initialized = true;

        /* Disable owner of implementation contract */
        renounceOwnership();
    }

    /**************************************************************************/
    /* Initializer */
    /**************************************************************************/

    /**
     * @notice PoolFactory initializator
     */
    function initialize() external {
        require(!_initialized, "Already initialized");

        _initialized = true;
        _transferOwnership(msg.sender);
    }

    /**************************************************************************/
    /* Primary API */
    /**************************************************************************/

    /*
     * @inheritdoc IPoolFactory
     */
    function create(address poolImplementation, bytes calldata params) external returns (address) {
        /* Validate pool implementation */
        if (!_allowedImplementations.contains(poolImplementation)) revert UnsupportedImplementation();

        /* Create pool instance */
        address poolInstance = Clones.clone(poolImplementation);
        Address.functionCall(poolInstance, abi.encodeWithSignature("initialize(bytes)", params));

        /* Add pool to registry */
        _pools.add(poolInstance);

        /* Emit Pool Created */
        emit PoolCreated(poolInstance, poolImplementation);

        return poolInstance;
    }

    /*
     * @inheritdoc IPoolFactory
     */
    function createProxied(address poolBeacon, bytes calldata params) external returns (address) {
        /* Validate pool implementation */
        if (!_allowedImplementations.contains(poolBeacon)) revert UnsupportedImplementation();

        /* Create pool instance */
        address poolInstance = address(
            new BeaconProxy(poolBeacon, abi.encodeWithSignature("initialize(bytes)", params))
        );

        /* Add pool to registry */
        _pools.add(poolInstance);

        /* Emit Pool Created */
        emit PoolCreated(poolInstance, poolBeacon);

        return poolInstance;
    }

    /**
     * @inheritdoc IPoolFactory
     */
    function isPool(address pool) public view returns (bool) {
        return _pools.contains(pool);
    }

    /**
     * @inheritdoc IPoolFactory
     */
    function getPools() external view returns (address[] memory) {
        return _pools.values();
    }

    /**
     * @inheritdoc IPoolFactory
     */
    function getPoolCount() external view returns (uint256) {
        return _pools.length();
    }

    /**
     * @inheritdoc IPoolFactory
     */
    function getPoolAt(uint256 index) external view returns (address) {
        return _pools.at(index);
    }

    /**
     * @inheritdoc IPoolFactory
     */
    function getPoolImplementations() external view returns (address[] memory) {
        return _allowedImplementations.values();
    }

    /**************************************************************************/
    /* Admin API */
    /**************************************************************************/

    /**
     * @notice Set pool admin fee rate
     * @param pool Pool address
     * @param rate Rate is the admin fee in basis points
     */
    function setAdminFeeRate(address pool, uint32 rate) external onlyOwner {
        /* Validate pool */
        if (!isPool(pool)) revert InvalidPool();

        Address.functionCall(pool, abi.encodeWithSignature("setAdminFeeRate(uint32)", rate));
    }

    /**
     * @notice Add pool implementation to allowlist
     * @param poolImplementation Pool implementation
     */
    function addPoolImplementation(address poolImplementation) external onlyOwner {
        if (_allowedImplementations.add(poolImplementation)) {
            emit PoolImplementationAdded(poolImplementation);
        }
    }

    /**
     * @notice Remove pool implementation from allowlist
     * @param poolImplementation Pool implementation
     */
    function removePoolImplementation(address poolImplementation) external onlyOwner {
        if (_allowedImplementations.remove(poolImplementation)) {
            emit PoolImplementationRemoved(poolImplementation);
        }
    }

    /**
     * @notice Get Proxy Implementation
     * @return Implementation address
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @notice Upgrade Proxy
     * @param newImplementation New implementation contract
     * @param data Optional calldata
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external onlyOwner {
        _upgradeToAndCall(newImplementation, data, false);
    }
}