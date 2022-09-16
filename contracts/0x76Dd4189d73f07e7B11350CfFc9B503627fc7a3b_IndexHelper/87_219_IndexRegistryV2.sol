// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IIndexFactory.sol";
import "../interfaces/IIndexRegistry.sol";
import "../interfaces/IPhuturePriceOracle.sol";

import "../FeePool.sol";
import "../NameRegistry.sol";

contract IndexRegistryV2Test is IIndexRegistry, NameRegistry {
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
    /// @notice Role for assets which should be skiped during index burning
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
    /// @notice Role for Uniswap/Sushiswap factory contract
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");

    mapping(address => uint) public override marketCapOf;
    uint public override totalMarketCap;

    uint public override maxComponents;

    address public override orderer;
    address public override priceOracle;
    address public override feePool;
    address public override indexLogic;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _indexLogic, uint _maxComponents) external override initializer {
        require(_indexLogic != address(0), "IndexRegistry: ZERO");
        require(_maxComponents >= 2, "IndexRegistry: INVALID");

        __NameRegistry_init();

        indexLogic = _indexLogic;
        maxComponents = _maxComponents;

        _setupRoles();
        _setupRoleAdmins();
    }

    function registerIndex(address _index, IIndexFactory.NameDetails calldata _nameDetails) external override {
        require(!hasRole(INDEX_ROLE, _index), "IndexRegistry: EXISTS");

        grantRole(INDEX_ROLE, _index);
        _setIndexName(_index, _nameDetails.name);
        _setIndexSymbol(_index, _nameDetails.symbol);
    }

    function setMaxComponents(uint _maxComponents) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_maxComponents >= 5, "IndexRegistry: INVALID");
        maxComponents = _maxComponents;
        emit SetMaxComponents(msg.sender, _maxComponents);
    }

    function setIndexLogic(address _indexLogic) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        indexLogic = _indexLogic;
        emit SetIndexLogic(msg.sender, _indexLogic);
    }

    function setPriceOracle(address _priceOracle) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        priceOracle = _priceOracle;
        emit SetPriceOracle(msg.sender, _priceOracle);
    }

    function setOrderer(address _orderer) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        orderer = _orderer;
        revert("IndexRegistry: FORBIDDEN");
    }

    function setFeePool(address _feePool) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        feePool = _feePool;
        emit SetFeePool(msg.sender, _feePool);
    }

    function addAsset(address _asset, uint _marketCap) external override {
        require(IPhuturePriceOracle(priceOracle).containsOracleOf(_asset), "IndexRegistry: ORACLE");
        grantRole(ASSET_ROLE, _asset);
        _updateAsset(_asset, _marketCap);
    }

    function removeAsset(address _asset) external override {
        _updateMarketCap(_asset, 0);
        revokeRole(ASSET_ROLE, _asset);
    }

    function updateAssetMarketCap(address _asset, uint _marketCap) external override onlyRole(ORACLE_ROLE) {
        _updateAsset(_asset, _marketCap);
    }

    function marketCapsOf(address[] calldata _assets)
        external
        view
        override
        returns (uint[] memory _marketCaps, uint _totalMarketCap)
    {
        _marketCaps = new uint[](_assets.length);
        for (uint i; i < _assets.length; ) {
            uint marketCap = marketCapOf[_assets[i]];
            _marketCaps[i] = marketCap;
            _totalMarketCap += marketCap;

            unchecked {
                i = i + 1;
            }
        }
    }

    function _updateAsset(address _asset, uint _marketCap) internal {
        require(_marketCap > 0, "IndexAssetRegistry: INVALID");

        _updateMarketCap(_asset, _marketCap);
        emit UpdateAsset(_asset, _marketCap);
    }

    function _updateMarketCap(address _asset, uint _marketCap) internal {
        require(hasRole(ASSET_ROLE, _asset), "IndexAssetRegistry: NOT_FOUND");

        totalMarketCap = totalMarketCap - marketCapOf[_asset] + _marketCap;
        marketCapOf[_asset] = _marketCap;
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IIndexRegistry).interfaceId || super.supportsInterface(_interfaceId);
    }

    function test() external pure returns (string memory) {
        return "Success";
    }

    /// @inheritdoc IIndexRegistry
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
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
}