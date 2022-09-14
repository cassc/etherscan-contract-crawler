// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/ProxyAddresses.sol";

/**
 * @title UpgradableProxy
 * @author Jeremy Guyet (@jguyet)
 * @dev Smart contract to implement on a contract proxy.
 * This contract allows the management of the important memory of a proxy.
 * The memory spaces are extremely far from the beginning of the memory
 * which allows a high security against collisions.
 * This contract allows updates using a DAO program governed by an
 * ERC20 governance token. A voting session is mandatory for each update.
 * All holders of at least one whole token are eligible to vote.
 * There are several memory locations dedicated to the proper functioning
 * of the proxy (Implementation, admin, governance, upgrades).
 * For more information about the security of these locations please refer
 * to the discussions around the EIP-1967 standard we have been inspired by.
 */
contract UpgradableProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @dev Returns the current Owner address.
     */
    function getOwner() external view returns (address) {
        return _getOwner();
    }

    /**
     * @dev Transfer the ownership onlyOwner can call this function.
     */
    function transferOwnership(address _newOwner) external payable {
        require(_getOwner() == msg.sender, "Proxy: FORBIDDEN");
        _setOwner(_newOwner);
    }

    /**
     * @dev Update function of the proxified implementation,
     */
    function upgrade(address _newImplementationAddress, bytes memory _initializationData) external payable {
        require(_getOwner() == msg.sender, "Proxy: FORBIDDEN");
        _upgrade(_newImplementationAddress, _initializationData);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return ProxyAddresses.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address _newImplementation) private {
        ProxyAddresses.getAddressSlot(_IMPLEMENTATION_SLOT).value = _newImplementation;
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _getOwner() internal view returns (address) {
        return ProxyAddresses.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setOwner(address _owner) private {
        ProxyAddresses.getAddressSlot(_ADMIN_SLOT).value = _owner;
    }

    /**
     * @dev Stores the new implementation address in the implementation slot
     * and call the internal _afterUpgrade function used for calling functions
     * on the new implementation just after the set in the same nonce block.
     */
    function _upgrade(address _newFunctionalAddress, bytes memory _initializationData) internal {
        _setImplementation(_newFunctionalAddress);
        _afterUpgrade(_newFunctionalAddress, _initializationData);
    }

    /**
     * @dev internal virtual function implemented in the Proxy contract.
     * This is called just after all upgrades of the proxy implementation.
     */
    function _afterUpgrade(address _newFunctionalAddress, bytes memory _initializationData) internal virtual { }

}