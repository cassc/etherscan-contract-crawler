// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SiloRouter.sol";
import "./interfaces/ISiloFactory.sol";
import "./interfaces/ISiloRepository.sol";
import "./interfaces/IPriceProvidersRepository.sol";
import "./interfaces/INotificationReceiver.sol";

import "./utils/GuardedLaunch.sol";
import "./Silo.sol";
import "./interfaces/ITokensFactory.sol";
import "./lib/Ping.sol";

/// @title SiloRepository
/// @notice SiloRepository handles the creation and configuration of Silos.
/// @dev Stores configuration for each asset in each silo.
/// Each asset in each Silo starts with a default config that later on can be changed by the contract owner.
/// Stores registry of Factory contracts that deploy different versions of Silos
/// It is possible to have multiple versions/implementations of Silo and use different versions for different
/// tokens. For example, one version can be used for UNI (ERC20) and the other can be used for UniV3LP tokens (ERC721).
/// Manages bridge assets. Each Silo can have 1 or more bridge assets. New Silos are created with all currently active
/// bridge assets. Silos that are already developed must synchronize bridge assets. Sync can be done by anyone,
/// function has public access.
/// Is a single source of truth for other contract addresses.
/// @custom:security-contact [email protected]
/* solhint-disable max-states-count */
contract SiloRepository is ISiloRepository, GuardedLaunch {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Default values for AssetConfig. Used if values are not configured manually.
    AssetConfig public defaultAssetConfig;

    /// @dev Protocol fee configuration
    Fees public fees;

    /// @dev Factory contracts that deploys debt and collateral tokens for each asset in Silo
    ITokensFactory public override tokensFactory;

    /// @dev PriceProvidersRepository contract that manages PriceProviders implementations and is an entry point
    /// for reading prices for Silos.
    IPriceProvidersRepository public override priceProvidersRepository;

    /// @dev SiloRouter utility contract that combines number of actions (Deposit, Withdraw, Borrow, Repay)
    /// for batch execution in single transaction.
    address public override router;

    /// @dev Silo for bridge asset. We can have only one bridge pool
    address public bridgePool;

    /// @dev Silo version data
    SiloVersion public siloVersion;

    /// @dev Maps asset => silo version
    mapping(address => uint128) public override getVersionForAsset;

    /// @dev Maps Silo address to incentive contract that will distribute rewards for that Silo
    mapping(address => INotificationReceiver) public override getNotificationReceiver;

    /// @dev Maps version => ISiloFactory. Versions start at 1 and are incremented by 1.
    mapping(uint256 => ISiloFactory) public override siloFactory;

    /// @dev maps token address to silo address, asset => silo
    mapping(address => address) public override getSilo;

    /// @dev maps silo address to token address, silo => asset
    mapping(address => address) public siloReverse;

    /// @dev maps silo => asset => config
    mapping(address => mapping(address => AssetConfig)) public assetConfigs;

    /// @dev Value used to initialize the Silo's version data
    uint128 private constant _INITIAL_SILO_VERSION = 1;

    /// @dev representation of 100%
    uint256 private constant _ONE_HUNDRED_PERCENT = 1e18;

    /// @dev List of bridge assets supported by the protocol
    EnumerableSet.AddressSet private _bridgeAssets;

    /// @dev List of bridge assets removed by the protocol
    EnumerableSet.AddressSet private _removedBridgeAssets;

    error AssetAlreadyAdded();
    error AssetIsNotABridge();
    error AssetIsZero();
    error BridgeAssetIsZero();
    error ConfigDidNotChange();
    error EmptyBridgeAssets();
    error FeesDidNotChange();
    error InterestRateModelDidNotChange();
    error InvalidEntryFee();
    error InvalidInterestRateModel();
    error InvalidLiquidationThreshold();
    error InvalidLTV();
    error InvalidNotificationReceiver();
    error InvalidPriceProvidersRepository();
    error InvalidProtocolLiquidationFee();
    error InvalidProtocolShareFee();
    error InvalidSiloFactory();
    error InvalidSiloRouter();
    error InvalidSiloVersion();
    error InvalidTokensFactory();
    error LastBridgeAsset();
    error LiquidationThresholdDidNotChange();
    error MaximumLTVDidNotChange();
    error VersionForAssetDidNotChange();
    error NoPriceProviderForAsset();
    error NotificationReceiverDidNotChange();
    error PriceProviderRepositoryDidNotChange();
    error RouterDidNotChange();
    error SiloAlreadyExistsForAsset();
    error SiloAlreadyExistsForBridgeAssets();
    error SiloDoesNotExist();
    error SiloIsZero();
    error SiloNotAllowedForBridgeAsset();
    error SiloVersionDoesNotExist();

    modifier ensureValidLiquidationThreshold(uint256 _ltv, uint256 _liquidationThreshold) {
        if (_liquidationThreshold >= _ONE_HUNDRED_PERCENT) {
            revert InvalidLiquidationThreshold();
        }

        if (_ltv == 0 || _ltv >= _liquidationThreshold) {
            revert InvalidLTV();
        }

        _;
    }

    /// @param _siloFactory address of SiloFactory contract that deploys Silos
    /// @param _tokensFactory address of TokensFactory contract that deploys debt and collateral tokens
    /// for each Silo asset
    /// @param _defaultMaxLTV maximum Loan-to-Value for default configuration
    /// @param _defaultLiquidationThreshold liquidation threshold for default configuration
    /// @param _initialBridgeAssets bridge assets to start with
    constructor(
        address _siloFactory,
        address _tokensFactory,
        uint64 _defaultMaxLTV,
        uint64 _defaultLiquidationThreshold,
        address[] memory _initialBridgeAssets
    )
        ensureValidLiquidationThreshold(_defaultMaxLTV, _defaultLiquidationThreshold) GuardedLaunch()
    {
        if (!Ping.pong(ISiloFactory(_siloFactory).siloFactoryPing)) {
            revert InvalidSiloFactory();
        }

        if (!Ping.pong(ITokensFactory(_tokensFactory).tokensFactoryPing)) {
            revert InvalidTokensFactory();
        }

        if (_initialBridgeAssets.length == 0) revert EmptyBridgeAssets();

        ISiloFactory(_siloFactory).initRepository(address(this));
        ITokensFactory(_tokensFactory).initRepository(address(this));

        for (uint256 i = 0; i < _initialBridgeAssets.length; i++) {
            TokenHelper.assertAndGetDecimals(_initialBridgeAssets[i]);
            _bridgeAssets.add(_initialBridgeAssets[i]);
            emit BridgeAssetAdded(_initialBridgeAssets[i]);
        }

        siloVersion.byDefault = _INITIAL_SILO_VERSION;
        siloVersion.latest = _INITIAL_SILO_VERSION;
        siloFactory[_INITIAL_SILO_VERSION] = ISiloFactory(_siloFactory);
        emit RegisterSiloVersion(_siloFactory, _INITIAL_SILO_VERSION, _INITIAL_SILO_VERSION);
        emit SiloDefaultVersion(_INITIAL_SILO_VERSION);

        tokensFactory = ITokensFactory(_tokensFactory);
        emit TokensFactoryUpdate(_tokensFactory);

        defaultAssetConfig.maxLoanToValue = _defaultMaxLTV;
        defaultAssetConfig.liquidationThreshold = _defaultLiquidationThreshold;
    }

    /// @inheritdoc ISiloRepository
    function setVersionForAsset(address _siloAsset, uint128 _version) external override onlyOwner {
        if (getVersionForAsset[_siloAsset] == _version) revert VersionForAssetDidNotChange();

        if (_version != 0 && address(siloFactory[_version]) == address(0)) {
            revert InvalidSiloVersion();
        }

        emit VersionForAsset(_siloAsset, _version);
        getVersionForAsset[_siloAsset] = _version;
    }

    /// @inheritdoc ISiloRepository
    function setTokensFactory(address _tokensFactory) external override onlyOwner {
        if (!Ping.pong(ITokensFactory(_tokensFactory).tokensFactoryPing)) {
            revert InvalidTokensFactory();
        }

        emit TokensFactoryUpdate(_tokensFactory);
        tokensFactory = ITokensFactory(_tokensFactory);
    }

    /// @inheritdoc ISiloRepository
    function setFees(Fees calldata _fees) external override onlyOwner {
        if (_fees.entryFee >= Solvency._PRECISION_DECIMALS) {
            revert InvalidEntryFee();
        }

        if (_fees.protocolShareFee >= Solvency._PRECISION_DECIMALS) {
            revert InvalidProtocolShareFee();
        }

        if (_fees.protocolLiquidationFee >= Solvency._PRECISION_DECIMALS) {
            revert InvalidProtocolLiquidationFee();
        }

        Fees memory currentFees = fees;

        if (
            _fees.entryFee == currentFees.entryFee &&
            _fees.protocolShareFee == currentFees.protocolShareFee &&
            _fees.protocolLiquidationFee == currentFees.protocolLiquidationFee
        ) {
            revert FeesDidNotChange();
        }

        emit FeeUpdate(_fees.entryFee, _fees.protocolShareFee, _fees.protocolLiquidationFee);
        fees = _fees;
    }

    /// @inheritdoc ISiloRepository
    function setAssetConfig(address _silo, address _asset, AssetConfig calldata _assetConfig)
        external
        override
        ensureValidLiquidationThreshold(_assetConfig.maxLoanToValue, _assetConfig.liquidationThreshold)
        onlyOwner
    {
        if (_silo == address(0)) revert SiloIsZero();

        if (_asset == address(0)) revert AssetIsZero();

        if (
            !Ping.pong(_assetConfig.interestRateModel.interestRateModelPing) ||
            _assetConfig.interestRateModel.DP() == 0
        ) {
            revert InvalidInterestRateModel();
        }

        AssetConfig memory currentConfig = assetConfigs[_silo][_asset];

        if (
            currentConfig.maxLoanToValue == _assetConfig.maxLoanToValue &&
            currentConfig.liquidationThreshold == _assetConfig.liquidationThreshold &&
            currentConfig.interestRateModel == _assetConfig.interestRateModel
        ) {
            revert ConfigDidNotChange();
        }

        emit AssetConfigUpdate(_silo, _asset, _assetConfig);
        assetConfigs[_silo][_asset] = _assetConfig;
    }

    /// @inheritdoc ISiloRepository
    function setDefaultInterestRateModel(IInterestRateModel _defaultInterestRateModel) external override onlyOwner {
        if (!Ping.pong(_defaultInterestRateModel.interestRateModelPing)) {
            revert InvalidInterestRateModel();
        }

        if (defaultAssetConfig.interestRateModel == _defaultInterestRateModel) {
            revert InterestRateModelDidNotChange();
        }

        emit InterestRateModel(_defaultInterestRateModel);
        defaultAssetConfig.interestRateModel = _defaultInterestRateModel;
    }

    /// @inheritdoc ISiloRepository
    function setDefaultMaximumLTV(uint64 _defaultMaxLTV)
        external
        override
        ensureValidLiquidationThreshold(_defaultMaxLTV, defaultAssetConfig.liquidationThreshold)
        onlyOwner
    {
        if (defaultAssetConfig.maxLoanToValue == _defaultMaxLTV) {
            revert MaximumLTVDidNotChange();
        }

        defaultAssetConfig.maxLoanToValue = _defaultMaxLTV;
        emit NewDefaultMaximumLTV(_defaultMaxLTV);
    }

    /// @inheritdoc ISiloRepository
    function setDefaultLiquidationThreshold(uint64 _defaultLiquidationThreshold)
        external
        override
        ensureValidLiquidationThreshold(defaultAssetConfig.maxLoanToValue, _defaultLiquidationThreshold)
        onlyOwner
    {
        if (defaultAssetConfig.liquidationThreshold == _defaultLiquidationThreshold) {
            revert LiquidationThresholdDidNotChange();
        }

        defaultAssetConfig.liquidationThreshold = _defaultLiquidationThreshold;
        emit NewDefaultLiquidationThreshold(_defaultLiquidationThreshold);
    }

    /// @inheritdoc ISiloRepository
    function setPriceProvidersRepository(IPriceProvidersRepository _repository) external override onlyOwner {
        if (!Ping.pong(_repository.priceProvidersRepositoryPing)) {
            revert InvalidPriceProvidersRepository();
        }

        if (priceProvidersRepository == _repository) {
            revert PriceProviderRepositoryDidNotChange();
        }

        emit PriceProvidersRepositoryUpdate(_repository);
        priceProvidersRepository = _repository;
    }

    /// @inheritdoc ISiloRepository
    function setRouter(address _router) external override onlyOwner {
        if (!Ping.pong(SiloRouter(payable(_router)).siloRouterPing)) {
            revert InvalidSiloRouter();
        }

        if (router == _router) revert RouterDidNotChange();

        emit RouterUpdate(_router);
        router = _router;
    }

    /// @inheritdoc ISiloRepository
    function setNotificationReceiver(
        address _silo,
        INotificationReceiver _newNotificationReceiver
    ) external override onlyOwner {
        if (!Ping.pong(_newNotificationReceiver.notificationReceiverPing)) {
            revert InvalidNotificationReceiver();
        }

        if (getNotificationReceiver[_silo] == _newNotificationReceiver) {
            revert NotificationReceiverDidNotChange();
        }

        emit NotificationReceiverUpdate(_newNotificationReceiver);
        getNotificationReceiver[_silo] = _newNotificationReceiver;
    }

    /// @inheritdoc ISiloRepository
    function addBridgeAsset(address _newBridgeAsset) external override onlyOwner {
        if (!priceProvidersRepository.providersReadyForAsset(_newBridgeAsset)) {
            revert NoPriceProviderForAsset();
        }

        TokenHelper.assertAndGetDecimals(_newBridgeAsset);

        // We need to add first, so it can be synchronized after
        if (!_bridgeAssets.add(_newBridgeAsset)) revert AssetAlreadyAdded();
        // We don't care about the return value, because we are doing this even if the asset isn't in the list
        _removedBridgeAssets.remove(_newBridgeAsset);

        emit BridgeAssetAdded(_newBridgeAsset);

        address silo = getSilo[_newBridgeAsset];
        address bridge = bridgePool;

        // Check if we already have silo for the new bridge asset.
        // Note that if there are at least two bridge assets in the system, it is possible to prevent the addition
        // of a specific new bridge asset by creating a Silo for it.
        if (silo != address(0)) {
            // Silo for new bridge asset exists, if we already have bridge, then revert
            if (bridge != address(0)) revert SiloAlreadyExistsForBridgeAssets();

            bridgePool = silo;
            bridge = silo;
            emit BridgePool(silo);
        }

        // syncBridgeAssets when:
        // - we discovered bridge pool, we need to sync it with new bridge asset
        // - silo for asset does not exist, but if we already have bridge, we need to sync
        if (bridge != address(0)) ISilo(bridge).syncBridgeAssets();
    }

    /// @inheritdoc ISiloRepository
    function removeBridgeAsset(address _bridgeAssetToRemove) external override onlyOwner {
        if (_bridgeAssetToRemove == address(0)) revert BridgeAssetIsZero();

        if (_bridgeAssets.length() == 1) revert LastBridgeAsset();

        if (!_bridgeAssets.remove(_bridgeAssetToRemove)) revert AssetIsNotABridge();

        _removedBridgeAssets.add(_bridgeAssetToRemove);
        emit BridgeAssetRemoved(_bridgeAssetToRemove);

        address silo = getSilo[_bridgeAssetToRemove];

        // we have silo and it is for sure bridge pool
        if (silo != address(0)) {
            ISilo(silo).syncBridgeAssets();
            bridgePool = address(0);
            emit BridgePool(address(0));
            return;
        }

        address pool = bridgePool;

        // we have bridge pool but it is not directly for `_bridgeAssetToRemove`
        if (pool != address(0)) {
            ISilo(pool).syncBridgeAssets();
        }
    }

    /// @inheritdoc ISiloRepository
    function newSilo(address _siloAsset, bytes memory _siloData) external override returns (address) {
        bool assetIsABridge = _bridgeAssets.contains(_siloAsset);
        ensureCanCreateSiloFor(_siloAsset, assetIsABridge);
        
        return _createSilo(_siloAsset, getVersionForAsset[_siloAsset], assetIsABridge, _siloData);
    }

    /// @inheritdoc ISiloRepository
    function replaceSilo(
        address _siloAsset,
        uint128 _siloVersion,
        bytes memory _siloData
    ) external override onlyOwner returns (address) {
        address siloToReplace = getSilo[_siloAsset];

        if (siloToReplace == address(0)) revert SiloDoesNotExist();

        return _createSilo(_siloAsset, _siloVersion, _bridgeAssets.contains(_siloAsset), _siloData);
    }

    /// @inheritdoc ISiloRepository
    function registerSiloVersion(ISiloFactory _factory, bool _isDefault) external override onlyOwner {
        if (!Ping.pong(_factory.siloFactoryPing)) revert InvalidSiloFactory();

        SiloVersion memory v = siloVersion;
        v.latest += 1;

        siloFactory[v.latest] = _factory;

        emit RegisterSiloVersion(address(_factory), v.latest, v.byDefault);

        if (_isDefault) {
            v.byDefault = v.latest;
            emit SiloDefaultVersion(v.latest);
        }

        siloVersion = v;
    }

    /// @inheritdoc ISiloRepository
    function unregisterSiloVersion(uint128 _siloVersion) external override onlyOwner {
        address factory = address(siloFactory[_siloVersion]);
        // Can't unregister nonexistent or default silo version
        if (factory == address(0) || _siloVersion == siloVersion.byDefault) {
            revert InvalidSiloVersion();
        }

        emit UnregisterSiloVersion(factory, _siloVersion);
        siloFactory[_siloVersion] = ISiloFactory(address(0));
    }

    /// @inheritdoc ISiloRepository
    function setDefaultSiloVersion(uint128 _defaultVersion) external override onlyOwner {
        if (address(siloFactory[_defaultVersion]) == address(0)) {
            revert SiloVersionDoesNotExist();
        }

        emit SiloDefaultVersion(_defaultVersion);
        siloVersion.byDefault = _defaultVersion;
    }

    /// @inheritdoc ISiloRepository
    function entryFee() external view override returns (uint256) {
        return fees.entryFee;
    }

    /// @inheritdoc ISiloRepository
    function protocolShareFee() external view override returns (uint256) {
        return fees.protocolShareFee;
    }

    /// @inheritdoc ISiloRepository
    function protocolLiquidationFee() external view override returns (uint256) {
        return fees.protocolLiquidationFee;
    }

    /// @inheritdoc ISiloRepository
    function isSilo(address _silo) external view override returns (bool) {
        return siloReverse[_silo] != address(0);
    }

    /// @inheritdoc ISiloRepository
    function getBridgeAssets() external view override returns (address[] memory) {
        return _bridgeAssets.values();
    }

    /// @inheritdoc ISiloRepository
    function getRemovedBridgeAssets() external view override returns (address[] memory) {
        return _removedBridgeAssets.values();
    }

    /// @inheritdoc ISiloRepository
    function getMaximumLTV(address _silo, address _asset) external view override returns (uint256) {
        uint256 maxLoanToValue = assetConfigs[_silo][_asset].maxLoanToValue;
        if (maxLoanToValue != 0) {
            return maxLoanToValue;
        }
        return defaultAssetConfig.maxLoanToValue;
    }

    /// @inheritdoc ISiloRepository
    function getInterestRateModel(address _silo, address _asset)
        external
        view
        override
        returns (IInterestRateModel model)
    {
        model = assetConfigs[_silo][_asset].interestRateModel;

        if (address(model) == address(0)) {
            return defaultAssetConfig.interestRateModel;
        }
    }

    /// @inheritdoc ISiloRepository
    function getLiquidationThreshold(address _silo, address _asset) external view override returns (uint256) {
        uint256 liquidationThreshold = assetConfigs[_silo][_asset].liquidationThreshold;

        if (liquidationThreshold != 0) {
            return liquidationThreshold;
        }

        return defaultAssetConfig.liquidationThreshold;
    }

    /// @inheritdoc ISiloRepository
    function siloRepositoryPing() external pure override returns (bytes4) {
        return this.siloRepositoryPing.selector;
    }

    /// @inheritdoc ISiloRepository
    function ensureCanCreateSiloFor(address _asset, bool _assetIsABridge) public view override {
        if (getSilo[_asset] != address(0)) revert SiloAlreadyExistsForAsset();

        if (_assetIsABridge) {
            if (bridgePool != address(0)) revert SiloAlreadyExistsForBridgeAssets();

            if (_bridgeAssets.length() == 1) revert SiloNotAllowedForBridgeAsset();
        }
    }

    /// @inheritdoc ISiloRepository
    function owner() public view override(ISiloRepository, GuardedLaunch) returns (address) {
        return GuardedLaunch.owner();
    }

    /// @dev Deploys Silo
    /// @param _siloAsset silo asset
    /// @param _siloVersion version of silo implementation
    /// @param _assetIsABridge flag indicating if asset is a bridge asset
    /// @param _siloData (optional) data that may be needed during silo creation
    function _createSilo(
        address _siloAsset,
        uint128 _siloVersion,
        bool _assetIsABridge,
        bytes memory _siloData
    ) internal returns (address createdSilo) {
        // 0 means default version
        if (_siloVersion == 0) {
            _siloVersion = siloVersion.byDefault;
        }

        ISiloFactory factory = siloFactory[_siloVersion];

        if (address(factory) == address(0)) revert InvalidSiloVersion();

        createdSilo = factory.createSilo(_siloAsset, _siloVersion, _siloData);

        // We do this before the asset sync so that functions like `isSilo` can be used by factories
        getSilo[_siloAsset] = createdSilo;
        siloReverse[createdSilo] = _siloAsset;

        Silo(createdSilo).syncBridgeAssets();

        emit NewSilo(createdSilo, _siloAsset, _siloVersion);

        if (_assetIsABridge) {
            bridgePool = createdSilo;
            emit BridgePool(createdSilo);
        }
    }
}