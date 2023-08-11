// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Errors} from "../libraries/Errors.sol";

/**
 * @title AddressesRegistry
 * @author Souq.Finance
 * @notice The Addresses registry of the souq protocol
 * @notice License: https://souq-peripheral-v1.s3.amazonaws.com/LICENSE.md
 */

contract AddressesRegistry is IAddressesRegistry, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    //Addresses mapping
    mapping(bytes32 => address) private addresses;
    uint256 public version;
    //global contract ids
    bytes32 private constant CONNECTORS_ROUTER = "CONNECTORS_ROUTER";
    bytes32 private constant ACCESS_MANAGER = "ACCESS_MANAGER";
    bytes32 private constant ACCESS_ADMIN = "ACCESS_ADMIN";
    //Factory contract short ids to full ids mappings
    //Example: SVS -> POOL_FACTORY_SVS
    mapping(bytes32 => bytes32) public poolFactories;
    mapping(bytes32 => bytes32) public vaultFactories;

    function initialize() external initializer {
        __Ownable_init();
        version = 1;
    }

    /// @inheritdoc IAddressesRegistry
    function getAddress(bytes32 _id) public view returns (address) {
        return addresses[_id];
    }

    /**
     * @notice Internal function that sets the address of the identifier.
     * @param _id The id of the contract
     * @param _add The address to set
     */
    function _setAddress(bytes32 _id, address _add) internal {
        address oldAdd = addresses[_id];
        addresses[_id] = _add;
        emit AddressUpdated(_id, oldAdd, _add);
    }

    /// @inheritdoc IAddressesRegistry
    function setAddress(bytes32 _id, address _add) external onlyOwner {
        _setAddress(_id, _add);
    }

    /// @inheritdoc IAddressesRegistry
    function getConnectorsRouter() external view returns (address) {
        return getAddress(CONNECTORS_ROUTER);
    }

    /// @inheritdoc IAddressesRegistry
    function setConnectorsRouter(address _add) external onlyOwner {
        address oldAdd = addresses[CONNECTORS_ROUTER];
        _setAddress(CONNECTORS_ROUTER, _add);
        emit RouterUpdated(oldAdd, _add);
    }

    /// @inheritdoc IAddressesRegistry
    function getAccessManager() external view returns (address) {
        return getAddress(ACCESS_MANAGER);
    }

    /// @inheritdoc IAddressesRegistry
    function setAccessManager(address _add) external onlyOwner {
        address oldAdd = addresses[ACCESS_MANAGER];
        _setAddress(ACCESS_MANAGER, _add);
        emit AccessManagerUpdated(oldAdd, _add);
    }

    /// @inheritdoc IAddressesRegistry
    function getAccessAdmin() external view returns (address) {
        return getAddress(ACCESS_ADMIN);
    }

    /// @inheritdoc IAddressesRegistry
    function setAccessAdmin(address _add) external onlyOwner {
        address oldAdd = addresses[ACCESS_ADMIN];
        _setAddress(ACCESS_ADMIN, _add);
        emit AccessAdminUpdated(oldAdd, _add);
    }

    /// @inheritdoc IAddressesRegistry
    function getPoolFactoryAddress(bytes32 _id) external view returns (address) {
        return addresses[poolFactories[_id]];
    }

    function getIdFromPoolFactory(bytes32 _id) external view returns (bytes32) {
        return poolFactories[_id];
    }

    /// @inheritdoc IAddressesRegistry
    function setPoolFactory(bytes32 _id, address _add) external onlyOwner {
        address oldAdd = addresses[poolFactories[_id]];
        _setAddress(poolFactories[_id], _add);
        emit PoolFactoryUpdated(_id, oldAdd, _add);
    }

    /// @inheritdoc IAddressesRegistry
    function addPoolFactory(bytes32 _id, address _add) external onlyOwner {
        poolFactories[_id] = bytes32(abi.encodePacked("POOL_FACTORY_", _id));
        addresses[poolFactories[_id]] = _add;
        emit PoolFactoryAdded(_id, _add);
    }

    /// @inheritdoc IAddressesRegistry
    function getVaultFactoryAddress(bytes32 _id) external view returns (address) {
        return addresses[vaultFactories[_id]];
    }

    /// @inheritdoc IAddressesRegistry
    function getIdFromVaultFactory(bytes32 _id) external view returns (bytes32) {
        return vaultFactories[_id];
    }

    /// @inheritdoc IAddressesRegistry
    function setVaultFactory(bytes32 _id, address _add) external onlyOwner {
        address oldAdd = addresses[vaultFactories[_id]];
        _setAddress(vaultFactories[_id], _add);
        emit PoolFactoryUpdated(_id, oldAdd, _add);
    }

    /// @inheritdoc IAddressesRegistry
    function addVaultFactory(bytes32 _id, address _add) external onlyOwner {
        vaultFactories[_id] = bytes32(abi.encodePacked("VAULT_FACTORY_", _id));
        addresses[vaultFactories[_id]] = _add;
        emit VaultFactoryAdded(_id, _add);
    }

    /// @inheritdoc IAddressesRegistry
    function updateImplementation(bytes32 _id, address _logic, bytes memory _data) external onlyOwner {
        ERC1967Proxy proxy = new ERC1967Proxy(_logic, _data);
        addresses[_id] = address(proxy);
        emit ProxyDeployed(_id, _logic, address(proxy));
    }

    /// @inheritdoc IAddressesRegistry
    function updateProxy(bytes32 _id, address _logic) external onlyOwner {
        emit ProxyUpgraded(_id, _logic, addresses[_id]);
        UUPSUpgradeable(addresses[_id]).upgradeTo(_logic);
    }

    /**
     * @dev Internal function to permit the upgrade of the proxy.
     * @param newImplementation The new implementation contract address used for the upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        require(newImplementation != address(0), Errors.ADDRESS_IS_ZERO);
        version++;
    }
}