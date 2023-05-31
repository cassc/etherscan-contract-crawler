// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: snotrocket.eth

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import
    "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "./IFeeDebugger.sol";
import "./specs/IArtBlocks.sol";
import "./specs/IDigitalax.sol";
import "./specs/IFoundation.sol";
import "./specs/INiftyGateway.sol";

/**
 * @dev Tool to look up whether a given combination of token contract and
 *      address will satisfy the overrideAllowed function in Manifold's
 *      registry.
 */
contract FeeDebugger is ERC165, OwnableUpgradeable, IFeeDebugger {
    using AddressUpgradeable for address;

    /**
     * @dev Function that simulates the behavior of Manifold's overrideAllowed
     *      function, but allows the caller to pass in both the token address
     *      and the candidate address.
     */
    function overrideAllowed(address tokenAddress, address candidateAddress)
        public
        view
        returns (bool)
    {
        if (
            ERC165Checker.supportsInterface(
                tokenAddress, type(IAdminControl).interfaceId
            ) && IAdminControl(tokenAddress).isAdmin(candidateAddress)
        ) {
            return true;
        }

        try OwnableUpgradeable(tokenAddress).owner() returns (address owner) {
            if (owner == candidateAddress) return true;

            if (owner.isContract()) {
                try OwnableUpgradeable(owner).owner() returns (
                    address passThroughOwner
                ) {
                    if (passThroughOwner == candidateAddress) return true;
                } catch { }
            }
        } catch { }

        try IAccessControlUpgradeable(tokenAddress).hasRole(
            0x00, candidateAddress
        ) returns (bool hasRole) {
            if (hasRole) return true;
        } catch { }

        // Nifty Gateway overrides
        try INiftyBuilderInstance(tokenAddress).niftyRegistryContract()
        returns (address niftyRegistry) {
            try INiftyRegistry(niftyRegistry).isValidNiftySender(
                candidateAddress
            ) returns (bool valid) {
                return valid;
            } catch { }
        } catch { }

        // OpenSea overrides
        // Tokens already support Ownable

        // Foundation overrides
        try IFoundationTreasuryNode(tokenAddress).getFoundationTreasury()
        returns (address payable foundationTreasury) {
            try IFoundationTreasury(foundationTreasury).isAdmin(
                candidateAddress
            ) returns (bool isAdmin) {
                return isAdmin;
            } catch { }
        } catch { }

        // DIGITALAX overrides
        try IDigitalax(tokenAddress).accessControls() returns (
            address externalAccessControls
        ) {
            try IDigitalaxAccessControls(externalAccessControls).hasAdminRole(
                candidateAddress
            ) returns (bool hasRole) {
                if (hasRole) return true;
            } catch { }
        } catch { }

        // Art Blocks overrides
        try IArtBlocks(tokenAddress).admin() returns (address admin) {
            if (admin == candidateAddress) return true;
        } catch { }

        // Superrare overrides
        // Tokens and registry already support Ownable

        // Rarible overrides
        // Tokens already support Ownable

        return false;
    }
}