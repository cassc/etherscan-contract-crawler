// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "../interfaces/IIndexRegistry.sol";
import "../interfaces/IPhuturePriceOracle.sol";
import "../interfaces/IOrderer.sol";
import "../interfaces/IFeePool.sol";
import "./EmptyUpgradable.sol";

/// @title Index registry
/// @notice Contains core components, addresses and asset market capitalizations
/// @dev After initializing call next methods: setPriceOracle, setOrderer, setFeePool
contract TestIndexRegistry is IIndexRegistry, EmptyUpgradable {
    using ERC165CheckerUpgradeable for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Responsible for all index related permissions
    bytes32 internal constant INDEX_ADMIN_ROLE = keccak256("INDEX_ADMIN_ROLE");
    /// @notice Responsible for all asset related permissions
    bytes32 internal constant ASSET_ADMIN_ROLE = keccak256("ASSET_ADMIN_ROLE");
    /// @notice Responsible for all ordering related permissions
    bytes32 internal constant ORDERING_ADMIN_ROLE = keccak256("ORDERING_ADMIN_ROLE");
    /// @notice Responsible for all exchange related permissions
    bytes32 internal constant EXCHANGE_ADMIN_ROLE = keccak256("EXCHANGE_ADMIN_ROLE");

    /// @notice Role for index factory
    bytes32 internal constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    /// @notice Role for index
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Role allows index creation
    bytes32 internal constant INDEX_CREATOR_ROLE = keccak256("INDEX_CREATOR_ROLE");
    /// @notice Role allows configure fee related data/components
    bytes32 internal constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    /// @notice Role for asset
    bytes32 internal constant ASSET_ROLE = keccak256("ASSET_ROLE");
    /// @notice Role for assets which should be skipped during index burning
    bytes32 internal constant SKIPPED_ASSET_ROLE = keccak256("SKIPPED_ASSET_ROLE");
    /// @notice Role allows update asset's market caps and vault reserve
    bytes32 internal constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    /// @notice Role allows configure asset related data/components
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");
    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");
    /// @notice Role for orderer contract
    bytes32 internal constant ORDERER_ROLE = keccak256("ORDERER_ROLE");
    /// @notice Role allows configure ordering related data/components
    bytes32 internal constant ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");
    /// @notice Role allows order execution
    bytes32 internal constant ORDER_EXECUTOR_ROLE = keccak256("ORDER_EXECUTOR_ROLE");
    /// @notice Role allows perform validator's work
    bytes32 internal constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    /// @notice Role for keep3r job contract
    bytes32 internal constant KEEPER_JOB_ROLE = keccak256("KEEPER_JOB_ROLE");
    /// @notice Role for UniswapV2Factory contract
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");

    /// @inheritdoc IIndexRegistry
    mapping(address => uint) public override marketCapOf;
    /// @inheritdoc IIndexRegistry
    uint public override totalMarketCap;

    /// @inheritdoc IIndexRegistry
    uint public override maxComponents;

    /// @inheritdoc IIndexRegistry
    address public override orderer;
    /// @inheritdoc IIndexRegistry
    address public override priceOracle;
    /// @inheritdoc IIndexRegistry
    address public override feePool;
    /// @inheritdoc IIndexRegistry
    address public override indexLogic;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IIndexRegistry
    function initialize(address _indexLogic, uint _maxComponents) external override initializer {
        require(_indexLogic != address(0), "IndexRegistry: ZERO");
        require(_maxComponents >= 2, "IndexRegistry: INVALID");

        __EmptyUpgradable_init();

        indexLogic = _indexLogic;
        maxComponents = _maxComponents;

        _setupRoles();
        _setupRoleAdmins();
    }

    /// @inheritdoc IIndexRegistry
    function registerIndex(address _index, IIndexFactory.NameDetails calldata _nameDetails) external override {
        require(!hasRole(INDEX_ROLE, _index), "IndexRegistry: EXISTS");

        grantRole(INDEX_ROLE, _index);
    }

    /// @inheritdoc IIndexRegistry
    function setMaxComponents(uint _maxComponents) external override onlyRole(INDEX_MANAGER_ROLE) {
        require(_maxComponents >= 2, "IndexRegistry: INVALID");

        maxComponents = _maxComponents;
        emit SetMaxComponents(msg.sender, _maxComponents);
    }

    /// @inheritdoc IIndexRegistry
    function setIndexLogic(address _indexLogic) external override onlyRole(INDEX_MANAGER_ROLE) {
        require(_indexLogic != address(0), "IndexRegistry: ZERO");

        indexLogic = _indexLogic;
        emit SetIndexLogic(msg.sender, _indexLogic);
    }

    /// @inheritdoc IIndexRegistry
    function setPriceOracle(address _priceOracle) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(_priceOracle.supportsInterface(type(IPhuturePriceOracle).interfaceId), "IndexRegistry: INTERFACE");

        priceOracle = _priceOracle;
        emit SetPriceOracle(msg.sender, _priceOracle);
    }

    /// @inheritdoc IIndexRegistry
    function setOrderer(address _orderer) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_orderer.supportsInterface(type(IOrderer).interfaceId), "IndexRegistry: INTERFACE");

        if (orderer != address(0)) {
            revokeRole(ORDERER_ROLE, orderer);
        }

        orderer = _orderer;
        grantRole(ORDERER_ROLE, _orderer);
        emit SetOrderer(msg.sender, _orderer);
    }

    /// @inheritdoc IIndexRegistry
    function setFeePool(address _feePool) external override onlyRole(FEE_MANAGER_ROLE) {
        require(_feePool.supportsInterface(type(IFeePool).interfaceId), "IndexRegistry: INTERFACE");

        feePool = _feePool;
        emit SetFeePool(msg.sender, _feePool);
    }

    /// @inheritdoc IIndexRegistry
    function addAsset(address _asset, uint _marketCap) external override {
        require(IPhuturePriceOracle(priceOracle).containsOracleOf(_asset), "IndexRegistry: ORACLE");

        grantRole(ASSET_ROLE, _asset);
        _updateAsset(_asset, _marketCap);
    }

    /// @inheritdoc IIndexRegistry
    function removeAsset(address _asset) external override {
        _updateMarketCap(_asset, 0);
        revokeRole(ASSET_ROLE, _asset);
    }

    /// @inheritdoc IIndexRegistry
    function updateAssetMarketCap(address _asset, uint _marketCap) external override onlyRole(ORACLE_ROLE) {
        _updateAsset(_asset, _marketCap);
    }

    /// @inheritdoc IIndexRegistry
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    /// @inheritdoc IIndexRegistry
    function marketCapsOf(address[] calldata _assets)
        external
        view
        override
        returns (uint[] memory _marketCaps, uint _totalMarketCap)
    {
        uint assetsCount = _assets.length;
        _marketCaps = new uint[](assetsCount);

        for (uint i; i < assetsCount; ) {
            uint marketCap = marketCapOf[_assets[i]];
            _marketCaps[i] = marketCap;
            _totalMarketCap += marketCap;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IIndexRegistry).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Updates market capitalization of the given asset
    /// @dev Emits UpdateAsset event
    /// @param _asset Asset to update market cap of
    /// @param _marketCap Market capitalization value
    function _updateAsset(address _asset, uint _marketCap) internal {
        require(_marketCap > 0, "IndexAssetRegistry: INVALID");

        _updateMarketCap(_asset, _marketCap);
        emit UpdateAsset(_asset, _marketCap);
    }

    /// @notice Setups initial roles
    function _setupRoles() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(INDEX_ADMIN_ROLE, msg.sender);
        _setupRole(ASSET_ADMIN_ROLE, msg.sender);
        _setupRole(ORDERING_ADMIN_ROLE, msg.sender);
        _setupRole(EXCHANGE_ADMIN_ROLE, msg.sender);
    }

    /// @notice Setups initial role admins
    function _setupRoleAdmins() internal {
        _setRoleAdmin(FACTORY_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(INDEX_CREATOR_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(INDEX_MANAGER_ROLE, INDEX_ADMIN_ROLE);
        _setRoleAdmin(FEE_MANAGER_ROLE, INDEX_ADMIN_ROLE);

        _setRoleAdmin(INDEX_ROLE, FACTORY_ROLE);

        _setRoleAdmin(ASSET_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(SKIPPED_ASSET_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(ASSET_MANAGER_ROLE, ASSET_ADMIN_ROLE);
        _setRoleAdmin(RESERVE_MANAGER_ROLE, ASSET_ADMIN_ROLE);

        _setRoleAdmin(ORDERER_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(ORDERING_MANAGER_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(ORDER_EXECUTOR_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(VALIDATOR_ROLE, ORDERING_ADMIN_ROLE);
        _setRoleAdmin(KEEPER_JOB_ROLE, ORDERING_ADMIN_ROLE);

        _setRoleAdmin(EXCHANGE_FACTORY_ROLE, EXCHANGE_ADMIN_ROLE);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newImpl.supportsInterface(type(IIndexRegistry).interfaceId), "IndexRegistry: INTERFACE");
        super._authorizeUpgrade(_newImpl);
    }

    /// @notice Updates market capitalization of the given asset
    /// @param _asset Asset to update market cap of
    /// @param _marketCap Market capitalization value
    function _updateMarketCap(address _asset, uint _marketCap) internal {
        require(hasRole(ASSET_ROLE, _asset), "IndexAssetRegistry: NOT_FOUND");

        totalMarketCap = totalMarketCap - marketCapOf[_asset] + _marketCap;
        marketCapOf[_asset] = _marketCap;
    }

    uint256[43] private __gap;
}