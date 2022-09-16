// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IIndexRegistry.sol";

/// @title vToken factory
/// @notice Contains vToken creation logic
contract vTokenFactory is IvTokenFactory, UUPSUpgradeable, ERC165Upgradeable {
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure reserve related data/components
    bytes32 internal constant RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

    /// @inheritdoc IvTokenFactory
    address public override beacon;
    /// @notice Index registry address
    address internal registry;

    /// @inheritdoc IvTokenFactory
    mapping(address => address) public override vTokenOf;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "vTokenFactory: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IvTokenFactory
    function initialize(address _registry, address _vTokenImpl) external override initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "vTokenFactory: INTERFACE");

        __ERC165_init();
        __UUPSUpgradeable_init();

        registry = _registry;
        beacon = address(new UpgradeableBeacon(_vTokenImpl));
    }

    /// @inheritdoc IvTokenFactory
    function upgradeBeaconTo(address _vTokenImpl) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(_vTokenImpl.supportsInterface(type(IvToken).interfaceId), "vTokenFactory: INTERFACE");

        UpgradeableBeacon(beacon).upgradeTo(_vTokenImpl);
    }

    /// @inheritdoc IvTokenFactory
    function createVToken(address _asset) external override {
        require(vTokenOf[_asset] == address(0), "vTokenFactory: EXISTS");

        _createVToken(_asset);
    }

    /// @inheritdoc IvTokenFactory
    function createdVTokenOf(address _asset) external override returns (address) {
        if (vTokenOf[_asset] == address(0)) {
            _createVToken(_asset);
        }

        return vTokenOf[_asset];
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IvTokenFactory).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Creates vToken contract
    /// @param _asset Asset to create vToken for
    function _createVToken(address _asset) internal {
        address proxy = address(
            new BeaconProxy(beacon, abi.encodeWithSelector(IvToken.initialize.selector, _asset, registry))
        );
        vTokenOf[_asset] = proxy;

        emit VTokenCreated(proxy, _asset);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(RESERVE_MANAGER_ROLE) {
        require(_newImpl.supportsInterface(type(IvTokenFactory).interfaceId), "vTokenFactory: INTERFACE");
    }

    uint256[47] private __gap;
}