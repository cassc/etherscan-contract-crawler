// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { INFTRegistry } from "./interfaces/INFTRegistry.sol";
import { Allowlist } from "./Allowlist.sol";
import { Blocklist } from "./Blocklist.sol";

/**
 * A registry of allowlisted and blocklisted addresses and code hashes. This is intended to
 * be deployed as a shared oracle, and it would be wise to set the `adminAddress` to an entity
 * that's responsible (e.g. a smart contract that lets creators vote on which addresses/code
 * hashes to add/remove, and then calls the related functions on this contract).
 */
contract NFTRegistry is INFTRegistry, Ownable, Allowlist, Blocklist {
    /**
     * @notice Adds a contract address to the allowlist
     * @param contractAddress Address of allowed operator
     */
    function addAllowedContractAddress(address contractAddress) external virtual onlyOwner {
        super._addAllowedContractAddress(contractAddress);
    }

    /**
     * @notice Removes a contract address from the allowlist
     * @param contractAddress Address of allowed operator
     */
    function removeAllowedContractAddress(address contractAddress) external virtual onlyOwner {
        super._removeAllowedContractAddress(contractAddress);
    }

    /**
     * @notice Adds a contract address to the blocklist
     * @param contractAddress Address of blocked operator
     */
    function addBlockedContractAddress(address contractAddress) external virtual onlyOwner {
        super._addBlockedContractAddress(contractAddress);
    }

    /**
     * @notice Removes a contract address from the blocklist
     * @param contractAddress Address of blocked operator
     */
    function removeBlockedContractAddress(address contractAddress) external virtual onlyOwner {
        super._removeBlockedContractAddress(contractAddress);
    }

    /**
     * @notice Adds a codehash to the allowlist
     * @param codeHash Code hash of allowed contract
     */
    function addAllowedCodeHash(bytes32 codeHash) external virtual onlyOwner {
        super._addAllowedCodeHash(codeHash);
    }

    /**
     * @notice Removes a codehash from the allowlist
     * @param codeHash Code hash of allowed contract
     */
    function removeAllowedCodeHash(bytes32 codeHash) external virtual onlyOwner {
        super._removeAllowedCodeHash(codeHash);
    }

    /**
     * @notice Adds a codehash to the blocklist
     * @param codeHash Code hash of blocked contract
     */
    function addBlockedCodeHash(bytes32 codeHash) external virtual onlyOwner {
        super._addBlockedCodeHash(codeHash);
    }

    /**
     * @notice Removes a codehash from the blocklist
     * @param codeHash Code hash of blocked contract
     */
    function removeBlockedCodeHash(bytes32 codeHash) external virtual onlyOwner {
        super._removeBlockedCodeHash(codeHash);
    }

    /**
     * @notice Global killswitch for the allowlist
     * @param disabled Enables or disables the allowlist
     */
    function setAllowlistDisabled(bool disabled) external virtual onlyOwner {
        super._setAllowlistDisabled(disabled);
    }

    /**
     * @notice Global killswitch for the blocklist
     * @param disabled Enables or disables the blocklist
     */
    function setBlocklistDisabled(bool disabled) external virtual onlyOwner {
        super._setBlocklistDisabled(disabled);
    }

    /**
     * @notice Checks against the allowlist and blocklist (depending if either is enabled
     * or disabled) to see if the operator is allowed.
     * @dev This function checks the blocklist before checking the allowlist, causing the
     * blocklist to take precedent over the allowlist. Be aware that if an operator is on
     * the blocklist and allowlist, it will still be blocked.
     * @param operator Address of operator
     */
    function isAllowedOperator(address operator) external view virtual returns (bool) {
        if (!blocklistDisabled) {
            bool blocked = _isBlocked(operator);
            if (blocked) {
                return false;
            }
        }

        if (!allowlistDisabled) {
            return _isAllowed(operator);
        }

        return true;
    }
}