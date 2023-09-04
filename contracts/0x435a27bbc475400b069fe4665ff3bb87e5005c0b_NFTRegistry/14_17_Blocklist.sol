// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IBlocklist } from "./interfaces/IBlocklist.sol";

/**
 * A contract that keeps track of a list of blocked addresses and code hashes. This is
 * intended to be inherited by the Registry contract.
 */
contract Blocklist is IBlocklist {
    // contractAddress => blocked
    mapping(address => bool) public blockedContractAddresses;
    // codeHash => blocked
    mapping(bytes32 => bool) public blockedCodeHashes;
    bool public blocklistDisabled;

    event BlocklistDisabled(bool indexed blocklistDisabled);
    event BlockedContractAddressAdded(address indexed contractAddress);
    event BlockedContractAddressRemoved(address indexed contractAddress);
    event BlockedCodeHashAdded(bytes32 indexed codeHash);
    event BlockedCodeHashRemoved(bytes32 indexed codeHash);

    /**
     * @notice External function that Checks if operator is on the blocklist.
     * @param operator Address of operator
     */
    function isBlocked(address operator) external view virtual returns (bool) {
        return _isBlocked(operator);
    }

    /**
     * @notice External function that checks if operator is on the blocklist
     * @param operator - Contract address
     */
    function isBlockedContractAddress(address operator) external view returns (bool) {
        return _isBlockedContractAddress(operator);
    }

    /**
     * @notice External function that checks if codehash is on the blocklist
     * @param contractAddress - Contract address
     */
    function isBlockedCodeHash(address contractAddress) external view returns (bool) {
        return _isBlockedCodeHash(contractAddress.codehash);
    }

    /**
     * @notice A global killswitch to either enable or disable the blocklist. By default
     * it is not disabled.
     * @param disabled Status of the blocklist
     */
    function _setBlocklistDisabled(bool disabled) internal virtual {
        blocklistDisabled = disabled;
        emit BlocklistDisabled(disabled);
    }

    /**
     * @notice Add a contract to a registry
     * @param contractAddress - Contract address
     */
    function _addBlockedContractAddress(address contractAddress) internal virtual {
        blockedContractAddresses[contractAddress] = true;
        emit BlockedContractAddressAdded(contractAddress);
    }

    /**
     * @notice Remove a contract from a registry
     * @param contractAddress - Contract address
     */
    function _removeBlockedContractAddress(address contractAddress) internal virtual {
        delete blockedContractAddresses[contractAddress];
        emit BlockedContractAddressRemoved(contractAddress);
    }

    /**
     * @notice Add a codehash to a registry
     * @param codeHash - Codehash
     */
    function _addBlockedCodeHash(bytes32 codeHash) internal virtual {
        blockedCodeHashes[codeHash] = true;
        emit BlockedCodeHashAdded(codeHash);
    }

    /**
     * @notice Remove a codehash from a registry
     * @param codeHash - Codehash
     */
    function _removeBlockedCodeHash(bytes32 codeHash) internal virtual {
        delete blockedCodeHashes[codeHash];
        emit BlockedCodeHashRemoved(codeHash);
    }

    /**
     * @notice Checks if operator is on the blocklist. First checks to see if blocklist
     * is enabled, then checks against the address and code hash.
     * @param operator Address of operator
     */
    function _isBlocked(address operator) internal view returns (bool) {
        if (_isBlockedContractAddress(operator)) {
            return true;
        }

        if (operator.code.length > 0) {
            if (_isBlockedCodeHash(operator.codehash)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Checks if operator is on the blocklist
     * @param operator - Contract address
     */
    function _isBlockedContractAddress(address operator) internal view returns (bool) {
        return blockedContractAddresses[operator];
    }

    /**
     * @notice Checks if codehash is on the blocklist
     * @param codeHash - Codehash
     */
    function _isBlockedCodeHash(bytes32 codeHash) internal view returns (bool) {
        return blockedCodeHashes[codeHash];
    }
}