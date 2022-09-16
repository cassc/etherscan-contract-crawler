// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/FixedPoint112.sol";

import "./interfaces/IPriceOracle.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IPhuturePriceOracle.sol";

/// @title Phuture price oracle
/// @notice Aggregates all price oracles and works with them through IPriceOracle interface
contract PhuturePriceOracle is IPhuturePriceOracle, UUPSUpgradeable, ERC165Upgradeable {
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure asset related data/components
    bytes32 internal constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

    /// @notice Scaling factor for index price
    uint8 internal constant INDEX_PRICE_SCALING_FACTOR = 2;

    /// @inheritdoc IPhuturePriceOracle
    mapping(address => address) public override priceOracleOf;

    /// @notice Index registry address
    address public registry;

    /// @notice Base asset address
    address public base;

    /// @notice Decimals of base asset
    uint8 internal baseDecimals;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "PhuturePriceOracle: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IPhuturePriceOracle
    function initialize(address _registry, address _base) external override initializer {
        require(_base != address(0), "PhuturePriceOracle: ZERO");

        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "PhuturePriceOracle: INTERFACE");

        __UUPSUpgradeable_init();
        __ERC165_init();

        base = _base;
        baseDecimals = IERC20Metadata(_base).decimals();
        registry = _registry;
    }

    /// @inheritdoc IPhuturePriceOracle
    function setOracleOf(address _asset, address _oracle) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(_oracle.supportsInterface(type(IPriceOracle).interfaceId), "PhuturePriceOracle: INTERFACE");

        priceOracleOf[_asset] = _oracle;
    }

    /// @inheritdoc IPhuturePriceOracle
    function removeOracleOf(address _asset) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(priceOracleOf[_asset] != address(0), "PhuturePriceOracle: UNSET");

        delete priceOracleOf[_asset];
    }

    /// @inheritdoc IPriceOracle
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint) {
        if (_asset == base) {
            return FixedPoint112.Q112;
        }

        address priceOracle = priceOracleOf[_asset];
        require(priceOracle != address(0), "PhuturePriceOracle: UNSET");

        return IPriceOracle(priceOracle).refreshedAssetPerBaseInUQ(_asset);
    }

    /// @inheritdoc IPhuturePriceOracle
    function convertToIndex(uint _baseAmount, uint8 _indexDecimals) external view override returns (uint) {
        return (_baseAmount * 10**(_indexDecimals - INDEX_PRICE_SCALING_FACTOR)) / 10**baseDecimals;
    }

    /// @inheritdoc IPhuturePriceOracle
    function containsOracleOf(address _asset) external view override returns (bool) {
        return priceOracleOf[_asset] != address(0) || _asset == base;
    }

    /// @inheritdoc IPriceOracle
    function lastAssetPerBaseInUQ(address _asset) external view override returns (uint) {
        if (_asset == base) {
            return FixedPoint112.Q112;
        }

        address priceOracle = priceOracleOf[_asset];
        require(priceOracle != address(0), "PhuturePriceOracle: UNSET");

        return IPriceOracle(priceOracle).lastAssetPerBaseInUQ(_asset);
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IPhuturePriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyRole(ASSET_MANAGER_ROLE) {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IPriceOracle).interfaceId;
        interfaceIds[1] = type(IPhuturePriceOracle).interfaceId;
        require(_newImpl.supportsAllInterfaces(interfaceIds), "PhuturePriceOracle: INTERFACE");
    }

    uint256[47] private __gap;
}