// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract ProtocolRegistry is UUPSUpgradeable, Initializable, OwnableUpgradeable {

    mapping(bytes32 => address) private _addresses;

    bytes32 private constant VAULT_ADDRESS = "VAULT_ADDRESS";
    bytes32 private constant RELAYER_ADDRESS = "RELAYER_ADDRESS";
    bytes32 private constant UPGRADEABLE_BEACON_ADDRESS = "UPGRADEABLE_BEACON_ADDRESS";
    bytes32 private constant SIGNER_ADDRESS = "SIGNER_ADDRESS";

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init();
    }

    /**
     * @notice getAddress
     * @param _contractName string representing the contract you are looking for
     *
     * Use this function to get the locations of the deployed addresses;
     */
    function getAddress(bytes32 _contractName) public view returns (address) {
        return _addresses[_contractName];
    }

    /**
     * @notice setAddress
     * @param _contractName bytes32 name to lookup the contract
     * @param _contractLocation address of the deployment being referenced
     */
    function setAddress(bytes32 _contractName, address _contractLocation) internal returns (address) {
        _addresses[_contractName] = _contractLocation;
        return _contractLocation;
    }

    /**
     * @notice setSignerAddress
     * @param _signer address of the webacy signer
     * @return address of signer
     */
    function setSignerAddress(address _signer) external onlyOwner returns (address) {
        _addresses[SIGNER_ADDRESS] = _signer;
        return _signer;
    }

    /**
     * @notice geetSignerAddress
     * @return address of webacy signer
     */
    function getSignerAddress() external view returns (address) {
        return getAddress(SIGNER_ADDRESS);
    }

    /**
     * @notice getRelayerAddress
     * @return address of protocol contract matching RELAYER_ADDRESS value
     *
     */
    function getRelayerAddress() external view returns (address) {
        return getAddress(RELAYER_ADDRESS);
    }

    /**
     * @notice getVaultAddress
     * @return address of protocol contract matching VAULT_ADDRESS value
     *
     */
    function getVaultAddress() external view returns (address) {
        return getAddress(VAULT_ADDRESS);
    }

    /**
     * @notice getUpgradeableAddress
     * @return address of protocol contract matching UPGRADEABLE_BEACON_ADDRESS value
     *
     */
    function getUpgradeableAddress() external view returns (address) {
        return getAddress(UPGRADEABLE_BEACON_ADDRESS);
    }

    /**
     * @dev setVaultAddress
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setVaultAddress(address _contractLocation) external onlyOwner returns (address) {
        return setAddress(VAULT_ADDRESS, _contractLocation);
    }

    /**
     * @dev setRelayerAddress
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setRelayerAddress(address _contractLocation) external onlyOwner returns (address) {
        return setAddress(RELAYER_ADDRESS, _contractLocation);
    }

    /**
     * @dev setUpgradeableBeaconAddress
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setUpgradeableBeaconAddress(address _contractLocation) external onlyOwner returns (address) {
        return setAddress(UPGRADEABLE_BEACON_ADDRESS, _contractLocation);
    }

    /**
    * @inheritdoc UUPSUpgradeable
    */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}