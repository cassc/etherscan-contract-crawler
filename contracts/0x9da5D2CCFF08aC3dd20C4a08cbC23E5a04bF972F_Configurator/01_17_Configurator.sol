// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./libraries/helpers/Errors.sol";
import "./interfaces/ILedger.sol";
import "./types/DataTypes.sol";

contract Configurator is Initializable, AccessControlUpgradeable {

    uint256 public constant VERSION = 3;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    ILedger public ledger;

    event SetLedger(address indexed ledger);
    event SetLeverageFactor(uint256 leverageFactor);
    event SetTradeFee(uint256 tradeFee);
    event SetLiquidationRatio(uint256 liquidationRatio);
    event SetSwapBufferLimitPercentage(uint256 liquidationRatio);
    event SetTreasury(address indexed treasury);
    event InitializedAsset(uint256 indexed assetId, address indexed asset, DataTypes.AssetConfig configuration);
    event SetAssetMode(address indexed asset, DataTypes.AssetMode mode);
    event SetAssetSwapAdapter(address indexed asset, address indexed swapAdapter);
    event SetAssetOracle(address indexed asset, address indexed oracle);
    event InitializedReserve(uint256 indexed pid, address indexed asset);
    event InitializedCollateral(uint256 indexed pid, address indexed asset, address indexed reinvestment);
    event SetReserveDepositFee(address indexed asset, uint32 depositFeeMantissa);
    event SetReserveState(address indexed asset, DataTypes.AssetState state);
    event SetReserveMode(address indexed asset, DataTypes.AssetMode mode);
    event SetCollateralDepositFee(address indexed asset, address indexed reinvestment, uint32 depositFeeMantissa);
    event SetCollateralLTV(address indexed asset, address indexed reinvestment, uint256 ltv);
    event SetCollateralMinBalance(address indexed asset, address indexed reinvestment, uint256 minBalance);
    event SetCollateralState(address indexed asset, address indexed reinvestment, DataTypes.AssetState state);
    event SetReserveReinvestment(address indexed asset, address indexed oldReinvestment, address indexed newReinvestment);
    event SetReserveLongReinvestment(address indexed asset, address indexed oldReinvestment, address indexed newReinvestment);
    event SetCollateralReinvestment(address indexed asset, address indexed oldReinvestment, address indexed newReinvestment);
    event SetReserveBonusPool(address indexed asset, address indexed oldBonusPool, address indexed newBonusPool);

    function initialize() external initializer onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), Errors.CALLER_NOT_OPERATOR);
        _;
    }

    /**
     * @notice Set protocol ledger
     * @param ledger_ Ledger
     */
    function setLedger(address ledger_) external onlyOperator {
        require(address(ledger) == address(0), Errors.LEDGER_INITIALIZED);
        ledger = ILedger(ledger_);
        emit SetLedger(ledger_);
    }

    /**
     * @notice Set protocol leverage factor
     * @param leverageFactor leverage factor
     */
    function setLeverageFactor(uint256 leverageFactor) external onlyOperator {
        require(leverageFactor >= 1e18, Errors.INVALID_LEVERAGE_FACTOR);
        require(leverageFactor <= 10e18, Errors.INVALID_LEVERAGE_FACTOR);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.leverageFactor = leverageFactor;
        ledger.setProtocolConfig(config);
        emit SetLeverageFactor(leverageFactor);
    }

    /**
     * @notice Set protocol trade fee
     * @param tradeFeeMantissa trade fee mantissa
     */
    function setTradeFee(uint256 tradeFeeMantissa) external onlyOperator {
        require(tradeFeeMantissa <= 0.1e18, Errors.INVALID_TRADE_FEE);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.tradeFeeMantissa = tradeFeeMantissa;
        ledger.setProtocolConfig(config);
        emit SetTradeFee(tradeFeeMantissa);
    }

    /**
     * @notice Set protocol liquidation ratio
     * @param liquidationRatioMantissa liquidation ratio mantissa
     */
    function setLiquidationRatio(uint256 liquidationRatioMantissa) external onlyOperator {
        require(liquidationRatioMantissa >= 0.5e18, Errors.INVALID_LIQUIDATION_RATIO);
        require(liquidationRatioMantissa <= 0.9e18, Errors.INVALID_LIQUIDATION_RATIO);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.liquidationRatioMantissa = liquidationRatioMantissa;
        ledger.setProtocolConfig(config);
        emit SetLiquidationRatio(liquidationRatioMantissa);
    }

    /**
     * @notice Set swap buffer limit percentage
     * @param swapBufferLimitPercentage swap buffer limit percentage
     */
    function setSwapBufferLimitPercentage(uint256 swapBufferLimitPercentage) external onlyOperator {
        require(swapBufferLimitPercentage > 1e18, Errors.INVALID_SWAP_BUFFER_LIMIT);
        require(swapBufferLimitPercentage <= 1.2e18, Errors.INVALID_SWAP_BUFFER_LIMIT);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.swapBufferLimitPercentage = swapBufferLimitPercentage;
        ledger.setProtocolConfig(config);
        emit SetSwapBufferLimitPercentage(swapBufferLimitPercentage);
    }

    function setTreasury(address treasury) external onlyOperator {
        require(treasury != address(0), Errors.INVALID_ZERO_ADDRESS);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.treasury = treasury;
        ledger.setProtocolConfig(config);
        emit SetTreasury(treasury);
    }

    /**
     * @notice Initialize Asset
     * @param asset Asset address
     * @param decimals Asset decimals
     * @param kind Asset's kind
     * @param swapAdapter ISwapAdapter data
     * @param oracle IPriceOracle data
    */
    function initAsset(
        address asset,
        uint256 decimals,
        DataTypes.AssetKind kind,
        ISwapAdapter swapAdapter,
        IPriceOracleGetter oracle
    ) external onlyOperator {
        DataTypes.AssetConfig memory configuration = ledger.getAssetConfiguration(asset);

        require(configuration.assetId == 0, Errors.ASSET_INITIALIZED);

        uint256 assetId = ledger.initAssetConfiguration(asset);

        configuration = DataTypes.AssetConfig(
            assetId,
            uint8(decimals),
            kind,
            swapAdapter,
            oracle
        );

        ledger.setAssetConfiguration(asset, configuration);

        emit InitializedAsset(assetId, asset, configuration);
    }

    /**
    * @notice Setter of Asset SwapAdapter
    * @param asset Address
    * @param swapAdapter ISwapAdapter Data
    */
    function setAssetSwapAdapter(address asset, ISwapAdapter swapAdapter) external onlyOperator {
        DataTypes.AssetConfig memory configuration = ledger.getAssetConfiguration(asset);
        configuration.swapAdapter = swapAdapter;
        ledger.setAssetConfiguration(asset, configuration);
        emit SetAssetSwapAdapter(asset, address(swapAdapter));
    }

    /**
    * @notice Setter of Asset Oracle
    * @param asset Address
    * @param oracle IPriceOracleGetter Data
    */
    function setAssetOracle(address asset, IPriceOracleGetter oracle) external onlyOperator {
        DataTypes.AssetConfig memory configuration = ledger.getAssetConfiguration(asset);
        configuration.oracle = oracle;
        ledger.setAssetConfiguration(asset, configuration);
        emit SetAssetOracle(asset, address(oracle));
    }

    /**
    * @notice Initialize Reserve
    * @param asset Asset address
    * @param data InitReserveData object
    */
    function initReserve(address asset, DataTypes.InitReserveData memory data) external onlyOperator {
        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);

        require(assetConfig.assetId != 0, Errors.ASSET_NOT_INITIALIZED);

        uint256 pid = ledger.initReserve(asset);

        ledger.setReserveReinvestment(pid, data.reinvestment);
        ledger.setReserveBonusPool(pid, data.bonusPool);
        ledger.setReserveLongReinvestment(pid, data.longReinvestment);

        ledger.setReserveConfiguration(
            pid,
            DataTypes.ReserveConfiguration(
                data.depositFeeMantissa,
                data.protocolRateMantissaRay,
                data.utilizationBaseRateMantissaRay,
                data.kinkMantissaRay,
                data.multiplierAnnualRay,
                data.jumpMultiplierAnnualRay,
                data.state,
                data.mode
            )
        );

        emit InitializedReserve(pid, asset);
    }

    /**
    * @notice Setter of Reserve Interest Parameters
    * @param asset Address
    * @param protocolRateMantissa Protocol Rate
    * @param utilizationBaseRateMantissa Utilization Base Rate
    * @param kinkMantissa Kink
    * @param multiplierAnnual Multiplier Annual
    * @param jumpMultiplierAnnual Jump Multiplier Annual
    */
    function setReserveInterestParams(
        address asset,
        uint32 protocolRateMantissa,
        uint32 utilizationBaseRateMantissa,
        uint32 kinkMantissa,
        uint32 multiplierAnnual,
        uint32 jumpMultiplierAnnual
    ) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        reserve.configuration.protocolRateMantissaGwei = protocolRateMantissa;
        reserve.configuration.utilizationBaseRateMantissaGwei = utilizationBaseRateMantissa;
        reserve.configuration.kinkMantissaGwei = kinkMantissa;
        reserve.configuration.multiplierAnnualGwei = multiplierAnnual;
        reserve.configuration.jumpMultiplierAnnualGwei = jumpMultiplierAnnual;

        ledger.setReserveConfiguration(reserve.poolId, reserve.configuration);
    }

    /**
    * @notice Setter Reserve Fee
    * @param asset Address
    * @param fee Deposit Fee
    */
    function setReserveFee(address asset, uint32 fee) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);
        reserve.configuration.depositFeeMantissaGwei = fee;
        ledger.setReserveConfiguration(reserve.poolId, reserve.configuration);
        emit SetReserveDepositFee(asset, fee);
    }

    function setReserveState(address asset, DataTypes.AssetState state) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);
        reserve.configuration.state = state;
        ledger.setReserveConfiguration(reserve.poolId, reserve.configuration);
        emit SetReserveState(asset, state);
    }

    function setReserveMode(address asset, DataTypes.AssetMode mode) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);
        reserve.configuration.mode = mode;
        ledger.setReserveConfiguration(reserve.poolId, reserve.configuration);
        emit SetReserveMode(asset, mode);
    }

    /**
    * @notice Setter Reserve Fee
    * @param asset Address
    * @param bonusPool Bonus Pool address
    */
    function setReserveBonusPool(address asset, address bonusPool) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        ledger.setReserveBonusPool(reserve.poolId, bonusPool);

        emit SetReserveBonusPool(asset, reserve.ext.bonusPool, bonusPool);
    }

    /**
    * @notice Initialize Collateral
    * @param asset Address
    * @param reinvestment Address
    * @param depositFeeMantissa Deposit Fee
    * @param ltv LTV
    * @param minBalance Min Balance
    */
    function initCollateral(
        address asset,
        address reinvestment,
        uint32 depositFeeMantissa,
        uint32 ltv,
        uint128 minBalance
    ) external onlyOperator {
        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);

        require(assetConfig.assetId != 0, Errors.ASSET_NOT_INITIALIZED);

        uint256 pid = ledger.initCollateral(asset, reinvestment);

        ledger.setCollateralConfiguration(
            pid,
            DataTypes.CollateralConfiguration(
                depositFeeMantissa,
                ltv,
                minBalance,
                DataTypes.AssetState.Active
            ));

        emit InitializedCollateral(pid, asset, reinvestment);
    }

    /**
    * @notice Setter of Collateral Deposit Fee
    * @param asset Address
    * @param reinvestment Address
    * @param depositFeeMantissa Deposit Fee
    */
    function setCollateralDepositFee(
        address asset,
        address reinvestment,
        uint32 depositFeeMantissa
    ) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);
        collateral.configuration.depositFeeMantissaGwei = depositFeeMantissa;
        ledger.setCollateralConfiguration(collateral.poolId, collateral.configuration);
        emit SetCollateralDepositFee(asset, reinvestment, depositFeeMantissa);
    }

    /**
    * @notice Setter Collateral LTV
    * @param asset Address
    * @param reinvestment Address
    * @param ltv LTV
    */
    function setCollateralLTV(
        address asset,
        address reinvestment,
        uint32 ltv
    ) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);
        collateral.configuration.ltvGwei = ltv;
        ledger.setCollateralConfiguration(collateral.poolId, collateral.configuration);
        emit SetCollateralLTV(asset, reinvestment, ltv);
    }

    /**
    * @notice Setter of Collateral Minimum Balance
    * @param asset Address
    * @param reinvestment Address
    * @param minBalance Min Balance
    */
    function setCollateralMinBalance(address asset, address reinvestment, uint128 minBalance) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);
        collateral.configuration.minBalance = minBalance;
        ledger.setCollateralConfiguration(collateral.poolId, collateral.configuration);
        emit SetCollateralMinBalance(asset, reinvestment, minBalance);
    }

    /**
    * @notice Setter of Collateral State
    * @param asset Address
    * @param reinvestment Address
    * @param state AssetState Data
    */
    function setCollateralState(address asset, address reinvestment, DataTypes.AssetState state) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);
        collateral.configuration.state = state;
        ledger.setCollateralConfiguration(collateral.poolId, collateral.configuration);
        emit SetCollateralState(asset, reinvestment, state);
    }

    /**
    * @notice Setter of Reserve Reinvestment
    * @param asset Address
    * @param newReinvestment Address
    */
    function setReserveReinvestment(address asset, address newReinvestment) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        require(reserve.configuration.state == DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(reserve.ext.reinvestment != newReinvestment, Errors.INVALID_POOL_REINVESTMENT);

        (,,,uint256 currentSupply,) = ledger.reserveSupplies(asset);

        if (reserve.ext.reinvestment != address(0) && currentSupply > 0) {
            ledger.managePoolReinvestment(0, reserve.poolId);
        }

        ledger.setReserveReinvestment(reserve.poolId, newReinvestment);

        if (newReinvestment != address(0) && currentSupply > 0) {
            ledger.managePoolReinvestment(1, reserve.poolId);
        }

        emit SetReserveReinvestment(asset, reserve.ext.reinvestment, newReinvestment);
    }

    /**
    * @notice Setter of Reserve Reinvestment
    * @param asset Address
    * @param newReinvestment Address
    */
    function setReserveLongReinvestment(address asset, address newReinvestment) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        require(reserve.configuration.state == DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(reserve.ext.longReinvestment != newReinvestment, Errors.INVALID_POOL_REINVESTMENT);

        if (reserve.ext.longReinvestment != address(0) && reserve.longSupply > 0) {
            ledger.managePoolReinvestment(4, reserve.poolId);
        }

        ledger.setReserveLongReinvestment(reserve.poolId, newReinvestment);

        if (newReinvestment != address(0) && reserve.longSupply > 0) {
            ledger.managePoolReinvestment(5, reserve.poolId);
        }

        emit SetReserveLongReinvestment(asset, reserve.ext.longReinvestment, newReinvestment);
    }

    /**
    * @notice Setter Collateral Reinvestment
    * @param asset Address
    * @param reinvestment Address
    * @param newReinvestment address
    */
    function setCollateralReinvestment(address asset, address reinvestment, address newReinvestment) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);

        require(collateral.configuration.state == DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(collateral.reinvestment != newReinvestment, Errors.INVALID_POOL_REINVESTMENT);

        uint256 currentSupply = ledger.collateralTotalSupply(asset, reinvestment);

        // withdraw from curr reinvestment
        if (collateral.reinvestment != address(0) && currentSupply > 0) {
            ledger.managePoolReinvestment(2, collateral.poolId);
        }

        // set new reinvestment
        ledger.setCollateralReinvestment(collateral.poolId, newReinvestment);

        if (newReinvestment != address(0) && currentSupply > 0) {
            // reinvest to new reinvestment
            ledger.managePoolReinvestment(3, collateral.poolId);
        }

        emit SetCollateralReinvestment(asset, reinvestment, newReinvestment);
    }
}