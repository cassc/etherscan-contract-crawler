// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./interfaces/INameRegistry.sol";

/// @title Name registry
/// @notice Contains access control logic and information about names and symbols of indexes
abstract contract NameRegistry is INameRegistry, AccessControlUpgradeable, UUPSUpgradeable {
    using ERC165CheckerUpgradeable for address;

    /// @notice Role allows configure index related data/components
    bytes32 internal constant INDEX_MANAGER_ROLE = keccak256("INDEX_MANAGER_ROLE");

    /// @inheritdoc INameRegistry
    mapping(string => address) public override indexOfName;
    /// @inheritdoc INameRegistry
    mapping(string => address) public override indexOfSymbol;
    /// @inheritdoc INameRegistry
    mapping(address => string) public override nameOfIndex;
    /// @inheritdoc INameRegistry
    mapping(address => string) public override symbolOfIndex;

    /// @inheritdoc INameRegistry
    function setIndexName(address _index, string calldata _name) external override onlyRole(INDEX_MANAGER_ROLE) {
        _setIndexName(_index, _name);
    }

    /// @inheritdoc INameRegistry
    function setIndexSymbol(address _index, string calldata _symbol) external override onlyRole(INDEX_MANAGER_ROLE) {
        _setIndexSymbol(_index, _symbol);
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(INameRegistry).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Assigns name to the given index
    /// @param _index Index to assign name for
    /// @param _name Name to assign
    function _setIndexName(address _index, string calldata _name) internal {
        // make sure that name is unique and not set by any other index
        require(indexOfName[_name] == address(0), "NameRegistry: EXISTS");

        uint length = bytes(_name).length;
        require(length >= 1 && length <= 32, "NameRegistry: INVALID");

        delete indexOfName[nameOfIndex[_index]];
        indexOfName[_name] = _index;
        nameOfIndex[_index] = _name;

        emit SetName(_index, _name);
    }

    /// @notice Initializes name registry
    /// @dev Initialization method used in upgradeable contracts instead of constructor function
    function __NameRegistry_init() internal onlyInitializing {
        __AccessControl_init();
        __UUPSUpgradeable_init();
    }

    /// @notice Assigns symbol to the given index
    /// @param _index Index to assign symbol for
    /// @param _symbol Symbol to assign
    function _setIndexSymbol(address _index, string calldata _symbol) internal {
        // make sure that symbol is unique and not set by any other index
        require(indexOfSymbol[_symbol] == address(0), "NameRegistry: EXISTS");

        uint length = bytes(_symbol).length;
        require(length >= 3 && length <= 6, "NameRegistry: INVALID");

        delete indexOfSymbol[symbolOfIndex[_index]];
        indexOfSymbol[_symbol] = _index;
        symbolOfIndex[_index] = _symbol;

        emit SetSymbol(_index, _symbol);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newImpl.supportsInterface(type(INameRegistry).interfaceId), "NameRegistry: INTERFACE");
    }

    uint256[46] private __gap;
}