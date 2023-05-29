// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {IContractInfo} from "./IContractInfo.sol";
import {IOwnable} from "./IOwnable.sol";
import {IJSONExtensionRegistry} from "./IJSONExtensionRegistry.sol";

import {console2} from "forge-std/console2.sol";

/// @notice Zora Labs Implementation for JSON Extension Registry v1
/// @dev Repo: github.com/ourzora/json-extension-registry
/// @author @iainnash / @mattlenz
contract JSONExtensionRegistry is
    IJSONExtensionRegistry,
    ERC165,
    IContractInfo
{
    uint256 public immutable version = 1;

    mapping(address => string) getJSONExtensions;

    /// @notice isAdmin getter for a target address
    /// @param target target contract
    /// @param expectedAdmin expected admin contract
    function isAdmin(address target, address expectedAdmin)
        internal
        view
        returns (bool)
    {
        // If we're calling from the contract or EOA
        if (target == expectedAdmin) {
            return true;
        }
        if (target.code.length > 0) {
            // Check if the contract supports ownable()
            try IOwnable(target).owner() returns (address owner) {
                if (owner == expectedAdmin) {
                    return true;
                }
            } catch {}
            // Check if the contract supports accessControl and allow admins
            try
                IAccessControl(target).hasRole(bytes32(0x00), expectedAdmin)
            returns (bool hasRole) {
                if (hasRole) {
                    return true;
                }
            } catch {}
        }
        return false;
    }

    /// @notice Get user's admin status externally
    /// @param target contract to check admin status for
    /// @param expectedAdmin user to check if they are listed as an admin
    function getIsAdmin(address target, address expectedAdmin)
        external
        view
        returns (bool)
    {
        return isAdmin(target, expectedAdmin);
    }

    /// @notice Only allowed for contract admin
    /// @param target target contract
    /// @dev only allows contract admin of target (from msg.sender)
    modifier onlyAdmin(address target) {
        if (!isAdmin(target, msg.sender)) {
            revert RequiresContractAdmin();
        }

        _;
    }

    /**
        Contract Info Section
     */

    /// @notice Contract Name Getter
    /// @dev Used to identify contract
    /// @return string contract name
    function name() external pure returns (string memory) {
        return "JSONMetadataRegistry";
    }

    /// @notice Contract Information URI Getter
    /// @dev Used to provide contract information
    /// @return string contract information uri
    function contractInfo() external pure returns (string memory) {
        // return contract information uri
        return "https://docs.zora.co/json-contract-registry";
    }

    /** User setter IJSONExtensionRegistry */

    /// @notice Set address json extension file
    /// @dev Used to provide json extension information for rendering
    /// @param target target address to set metadata for
    /// @param uri uri to set metadata to
    function setJSONExtension(address target, string memory uri)
        external
        onlyAdmin(target)
    {
        getJSONExtensions[target] = uri;
        emit JSONExtensionUpdated({
            target: target,
            updater: msg.sender,
            newValue: uri
        });
    }

    /// @notice Getter for address json extension file
    /// @param target target contract for json extension
    /// @return address json extension for target
    function getJSONExtension(address target)
        external
        view
        returns (string memory)
    {
        return getJSONExtensions[target];
    }

    /// @notice See [EIP165]: EIP165 getter for json target
    /// @param interfaceId interfaceId to test support for
    /// @return boolean if the interfaceId is supported by the contract
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IJSONExtensionRegistry).interfaceId;
    }
}