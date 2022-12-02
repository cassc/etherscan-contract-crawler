// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VersionedInitializable} from "../libraries/paraspace-upgradeability/VersionedInitializable.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {ConfiguratorLogic} from "../libraries/logic/ConfiguratorLogic.sol";
import {ConfiguratorInputTypes} from "../libraries/types/ConfiguratorInputTypes.sol";
import {IPoolConfigurator} from "../../interfaces/IPoolConfigurator.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {IProtocolDataProvider} from "../../interfaces/IProtocolDataProvider.sol";

/**
 * @title PoolConfigurator
 *
 * @dev Implements the configuration methods for the ParaSpace protocol
 **/
contract PoolConfigurator is VersionedInitializable, IPoolConfigurator {
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    IPoolAddressesProvider internal _addressesProvider;
    IPool internal _pool;

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        _onlyPoolAdmin();
        _;
    }

    /**
     * @dev Only emergency admin can call functions marked by this modifier.
     **/
    modifier onlyEmergencyAdmin() {
        _onlyEmergencyAdmin();
        _;
    }

    /**
     * @dev Only emergency or pool admin can call functions marked by this modifier.
     **/
    modifier onlyEmergencyOrPoolAdmin() {
        _onlyPoolOrEmergencyAdmin();
        _;
    }

    /**
     * @dev Only asset listing or pool admin can call functions marked by this modifier.
     **/
    modifier onlyAssetListingOrPoolAdmins() {
        _onlyAssetListingOrPoolAdmins();
        _;
    }

    /**
     * @dev Only risk or pool admin can call functions marked by this modifier.
     **/
    modifier onlyRiskOrPoolAdmins() {
        _onlyRiskOrPoolAdmins();
        _;
    }

    uint256 public constant CONFIGURATOR_REVISION = 0x1;

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return CONFIGURATOR_REVISION;
    }

    function initialize(IPoolAddressesProvider provider) external initializer {
        _addressesProvider = provider;
        _pool = IPool(_addressesProvider.getPool());
    }

    /// @inheritdoc IPoolConfigurator
    function initReserves(
        ConfiguratorInputTypes.InitReserveInput[] calldata input
    ) external override onlyAssetListingOrPoolAdmins {
        IPool cachedPool = _pool;
        for (uint256 i = 0; i < input.length; i++) {
            ConfiguratorLogic.executeInitReserve(cachedPool, input[i]);
        }
    }

    /// @inheritdoc IPoolConfigurator
    function dropReserve(address asset) external override onlyPoolAdmin {
        _pool.dropReserve(asset);
        emit ReserveDropped(asset);
    }

    /// @inheritdoc IPoolConfigurator
    function updatePToken(
        ConfiguratorInputTypes.UpdatePTokenInput calldata input
    ) external override onlyPoolAdmin {
        ConfiguratorLogic.executeUpdatePToken(_pool, input);
    }

    /// @inheritdoc IPoolConfigurator
    function updateNToken(
        ConfiguratorInputTypes.UpdateNTokenInput calldata input
    ) external override onlyPoolAdmin {
        ConfiguratorLogic.executeUpdateNToken(_pool, input);
    }

    /// @inheritdoc IPoolConfigurator
    function updateVariableDebtToken(
        ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
    ) external override onlyPoolAdmin {
        ConfiguratorLogic.executeUpdateVariableDebtToken(_pool, input);
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveBorrowing(address asset, bool enabled)
        external
        override
        onlyRiskOrPoolAdmins
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        currentConfig.setBorrowingEnabled(enabled);
        _pool.setConfiguration(asset, currentConfig);
        emit ReserveBorrowing(asset, enabled);
    }

    /// @inheritdoc IPoolConfigurator
    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external override onlyRiskOrPoolAdmins {
        //validation of the parameters: the LTV can
        //only be lower or equal than the liquidation threshold
        //(otherwise a loan against the asset would cause instantaneous liquidation)
        require(ltv <= liquidationThreshold, Errors.INVALID_RESERVE_PARAMS);

        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);

        if (liquidationThreshold != 0) {
            //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
            //collateral than needed to cover the debt
            require(
                liquidationBonus >= PercentageMath.PERCENTAGE_FACTOR,
                Errors.INVALID_RESERVE_PARAMS
            );

            //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
            //a loan is taken there is enough collateral available to cover the liquidation bonus
            require(
                liquidationThreshold.percentMul(liquidationBonus) <=
                    PercentageMath.PERCENTAGE_FACTOR,
                Errors.INVALID_RESERVE_PARAMS
            );
        } else {
            require(liquidationBonus == 0, Errors.INVALID_RESERVE_PARAMS);
            //if the liquidation threshold is being set to 0,
            // the reserve is being disabled as collateral. To do so,
            //we need to ensure no liquidity is supplied
            _checkNoSuppliers(asset);
        }

        currentConfig.setLtv(ltv);
        currentConfig.setLiquidationThreshold(liquidationThreshold);
        currentConfig.setLiquidationBonus(liquidationBonus);

        _pool.setConfiguration(asset, currentConfig);

        emit CollateralConfigurationChanged(
            asset,
            ltv,
            liquidationThreshold,
            liquidationBonus
        );
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveActive(address asset, bool active)
        external
        override
        onlyPoolAdmin
    {
        if (!active) _checkNoSuppliers(asset);
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        currentConfig.setActive(active);
        _pool.setConfiguration(asset, currentConfig);
        emit ReserveActive(asset, active);
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveFreeze(address asset, bool freeze)
        external
        override
        onlyRiskOrPoolAdmins
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        currentConfig.setFrozen(freeze);
        _pool.setConfiguration(asset, currentConfig);
        emit ReserveFrozen(asset, freeze);
    }

    /// @inheritdoc IPoolConfigurator
    function setReservePause(address asset, bool paused)
        public
        override
        onlyEmergencyOrPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        currentConfig.setPaused(paused);
        _pool.setConfiguration(asset, currentConfig);
        emit ReservePaused(asset, paused);
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveFactor(address asset, uint256 newReserveFactor)
        external
        override
        onlyRiskOrPoolAdmins
    {
        require(
            newReserveFactor <= PercentageMath.PERCENTAGE_FACTOR,
            Errors.INVALID_RESERVE_FACTOR
        );
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        uint256 oldReserveFactor = currentConfig.getReserveFactor();
        currentConfig.setReserveFactor(newReserveFactor);
        _pool.setConfiguration(asset, currentConfig);
        emit ReserveFactorChanged(asset, oldReserveFactor, newReserveFactor);
    }

    /// @inheritdoc IPoolConfigurator
    function setSiloedBorrowing(address asset, bool newSiloed)
        external
        override
        onlyRiskOrPoolAdmins
    {
        if (newSiloed) {
            _checkNoBorrowers(asset);
        }
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);

        bool oldSiloed = currentConfig.getSiloedBorrowing();

        currentConfig.setSiloedBorrowing(newSiloed);

        _pool.setConfiguration(asset, currentConfig);

        emit SiloedBorrowingChanged(asset, oldSiloed, newSiloed);
    }

    /// @inheritdoc IPoolConfigurator
    function setBorrowCap(address asset, uint256 newBorrowCap)
        external
        override
        onlyRiskOrPoolAdmins
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        uint256 oldBorrowCap = currentConfig.getBorrowCap();
        currentConfig.setBorrowCap(newBorrowCap);
        _pool.setConfiguration(asset, currentConfig);
        emit BorrowCapChanged(asset, oldBorrowCap, newBorrowCap);
    }

    /// @inheritdoc IPoolConfigurator
    function setSupplyCap(address asset, uint256 newSupplyCap)
        external
        override
        onlyRiskOrPoolAdmins
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        uint256 oldSupplyCap = currentConfig.getSupplyCap();
        currentConfig.setSupplyCap(newSupplyCap);
        _pool.setConfiguration(asset, currentConfig);
        emit SupplyCapChanged(asset, oldSupplyCap, newSupplyCap);
    }

    /// @inheritdoc IPoolConfigurator
    function setLiquidationProtocolFee(address asset, uint256 newFee)
        external
        override
        onlyRiskOrPoolAdmins
    {
        require(
            newFee <= PercentageMath.PERCENTAGE_FACTOR,
            Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
        );
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        uint256 oldFee = currentConfig.getLiquidationProtocolFee();
        currentConfig.setLiquidationProtocolFee(newFee);
        _pool.setConfiguration(asset, currentConfig);
        emit LiquidationProtocolFeeChanged(asset, oldFee, newFee);
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveInterestRateStrategyAddress(
        address asset,
        address newRateStrategyAddress
    ) external override onlyRiskOrPoolAdmins {
        DataTypes.ReserveData memory reserve = _pool.getReserveData(asset);
        address oldRateStrategyAddress = reserve.interestRateStrategyAddress;
        _pool.setReserveInterestRateStrategyAddress(
            asset,
            newRateStrategyAddress
        );
        emit ReserveInterestRateStrategyChanged(
            asset,
            oldRateStrategyAddress,
            newRateStrategyAddress
        );
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveAuctionStrategyAddress(
        address asset,
        address newAuctionStrategyAddress
    ) external override onlyRiskOrPoolAdmins {
        DataTypes.ReserveData memory reserve = _pool.getReserveData(asset);
        address oldAuctionStrategyAddress = reserve.auctionStrategyAddress;
        _pool.setReserveAuctionStrategyAddress(
            asset,
            newAuctionStrategyAddress
        );
        emit ReserveAuctionStrategyChanged(
            asset,
            oldAuctionStrategyAddress,
            newAuctionStrategyAddress
        );
    }

    /// @inheritdoc IPoolConfigurator
    function setPoolPause(bool paused) external override onlyEmergencyAdmin {
        address[] memory reserves = _pool.getReservesList();

        for (uint256 i = 0; i < reserves.length; i++) {
            if (reserves[i] != address(0)) {
                setReservePause(reserves[i], paused);
            }
        }
    }

    /// @inheritdoc IPoolConfigurator
    function setAuctionRecoveryHealthFactor(uint64 value)
        external
        override
        onlyRiskOrPoolAdmins
    {
        _pool.setAuctionRecoveryHealthFactor(value);
    }

    function _checkNoSuppliers(address asset) internal view {
        uint256 totalXTokens = IProtocolDataProvider(
            _addressesProvider.getPoolDataProvider()
        ).getXTokenTotalSupply(asset);
        require(totalXTokens == 0, Errors.RESERVE_LIQUIDITY_NOT_ZERO);
    }

    function _checkNoBorrowers(address asset) internal view {
        uint256 totalDebt = IProtocolDataProvider(
            _addressesProvider.getPoolDataProvider()
        ).getTotalDebt(asset);
        require(totalDebt == 0, Errors.RESERVE_DEBT_NOT_ZERO);
    }

    function _onlyPoolAdmin() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
    }

    function _onlyEmergencyAdmin() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isEmergencyAdmin(msg.sender),
            Errors.CALLER_NOT_EMERGENCY_ADMIN
        );
    }

    function _onlyPoolOrEmergencyAdmin() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isPoolAdmin(msg.sender) ||
                aclManager.isEmergencyAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN
        );
    }

    function _onlyAssetListingOrPoolAdmins() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isAssetListingAdmin(msg.sender) ||
                aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
        );
    }

    function _onlyRiskOrPoolAdmins() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isRiskAdmin(msg.sender) ||
                aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_RISK_OR_POOL_ADMIN
        );
    }
}