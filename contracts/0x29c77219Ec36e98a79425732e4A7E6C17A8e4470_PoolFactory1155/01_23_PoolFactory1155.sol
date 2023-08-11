// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ProxyBeaconDeployer} from "../peripherals/ProxyBeaconDeployer.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";
import {IMME1155} from "../interfaces/IMME1155.sol";
import {IPoolFactory1155} from "../interfaces/IPoolFactory1155.sol";

/**
 * @title PoolFactory1155
 * @author Souq.Finance
 * @notice The Pool factory for MME1155 pools
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */
contract PoolFactory1155 is IPoolFactory1155, Initializable, UUPSUpgradeable, ProxyBeaconDeployer {
    DataTypes.FactoryFeeConfig public feeConfig;
    address private poolLogic;
    uint256 public version;
    uint256 public poolsVersion;
    bool public onlyPoolAdminDeployments;
    address[] public pools;
    IAddressesRegistry public immutable addressesRegistry;

    constructor(address registry) {
        require(registry != address(0), Errors.ADDRESS_IS_ZERO);
        addressesRegistry = IAddressesRegistry(registry);
    }

    function initialize(address _poolLogic, DataTypes.FactoryFeeConfig calldata _feeConfig) external initializer {
        require(_poolLogic != address(0), Errors.ADDRESS_IS_ZERO);
        poolLogic = _poolLogic;
        feeConfig = _feeConfig;
        onlyPoolAdminDeployments = false;
        version = 1;
        poolsVersion = 1;
    }

    /**
     * @dev modifier to check if the msg sender has role upgrader in the access manager
     */
    modifier onlyUpgrader() {
        require(IAccessManager(addressesRegistry.getAccessManager()).isUpgraderAdmin(msg.sender), Errors.CALLER_NOT_UPGRADER);
        _;
    }
    /**
     * @dev modifier to check if the msg sender has role pool admin in the access manager
     */
    modifier onlyPoolAdmin() {
        require(IAccessManager(addressesRegistry.getAccessManager()).isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
        _;
    }
    /**
     * @dev modifier to check if onlyPoolAdminDeployments is true and the msg sender has role pool admin in the access manager
     */
    modifier onlyDeployer() {
        if (onlyPoolAdminDeployments) {
            require(IAccessManager(addressesRegistry.getAccessManager()).isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
        }
        _;
    }

    /// @inheritdoc IPoolFactory1155
    function getFeeConfig() external view returns (DataTypes.FactoryFeeConfig memory) {
        return feeConfig;
    }

    /// @inheritdoc IPoolFactory1155
    function setFeeConfig(DataTypes.FactoryFeeConfig memory newConfig) external onlyPoolAdmin {
        feeConfig = newConfig;
        emit FeeConfigSet(msg.sender, feeConfig);
    }

    /// @inheritdoc IPoolFactory1155
    function deployPool(
        DataTypes.PoolData memory poolData,
        string memory symbol,
        string memory name
    ) external onlyDeployer returns (address) {
        //If buy/royalties ratio is out of bounds, then revert
        require(
            poolData.fee.lpBuyFee >= feeConfig.minLpFee &&
                poolData.fee.lpBuyFee <= feeConfig.maxLpBuyFee &&
                poolData.fee.lpSellFee >= feeConfig.minLpFee &&
                poolData.fee.lpSellFee <= feeConfig.maxLpSellFee &&
                poolData.fee.royaltiesBuyFee <= feeConfig.maxRoyaltiesFee &&
                poolData.fee.royaltiesSellFee <= feeConfig.maxRoyaltiesFee,
            Errors.FEE_OUT_OF_BOUNDS
        );
        //Set protocol fee ratio to the factory global ratio
        poolData.fee.protocolSellRatio = feeConfig.protocolSellRatio;
        poolData.fee.protocolBuyRatio = feeConfig.protocolBuyRatio;
        address proxy = deployBeaconProxy(poolLogic, "");
        pools.push(proxy);
        emit PoolDeployed(
            msg.sender,
            poolData.stable,
            poolData.tokens,
            proxy,
            pools.length - 1,
            symbol,
            name,
            poolData.liquidityLimit.poolTvlLimit
        );
        IMME1155(proxy).initialize(poolData, symbol, name);
        return proxy;
    }

    /// @inheritdoc IPoolFactory1155
    function getPool(uint256 index) external view returns (address) {
        return pools[index];
    }

    /// @inheritdoc IPoolFactory1155
    function getPoolsCount() external view returns (uint256) {
        return pools.length;
    }

    /// @inheritdoc IPoolFactory1155
    function upgradePools(address newLogic) external onlyUpgrader {
        require(newLogic != address(0), Errors.ADDRESS_IS_ZERO);
        emit PoolsUpgraded(msg.sender, newLogic);
        poolLogic = newLogic;
        //Change beacon logic
        upgradeBeacon(newLogic);
        ++poolsVersion;
    }

    /// @inheritdoc IPoolFactory1155
    function getPoolsVersion() external view returns (uint256) {
        return poolsVersion;
    }

    /// @inheritdoc IPoolFactory1155
    function getVersion() external view returns (uint256) {
        return version;
    }

    /// @inheritdoc IPoolFactory1155
    function setDeploymentByPoolAdminOnly(bool status) external onlyPoolAdmin {
        onlyPoolAdminDeployments = status;
        emit DeploymentByPoolAdminOnlySet(msg.sender, status);
    }

    /**
     * @dev Internal function to permit the upgrade of the proxy.
     * @param newImplementation The new implementation contract address used for the upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyUpgrader {
        require(newImplementation != address(0), Errors.ADDRESS_IS_ZERO);
        ++version;
    }
}