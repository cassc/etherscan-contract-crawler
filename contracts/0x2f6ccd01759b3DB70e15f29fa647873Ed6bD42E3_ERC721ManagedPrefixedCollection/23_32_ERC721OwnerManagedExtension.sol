// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./ERC721AutoIdMinterExtension.sol";

interface IERC721OwnerManagedExtension {
    function revokeManagementPower() external;
}

/**
 * @dev Extension to allow owner to transfer tokens on behalf of owners. Only useful for certain use-cases.
 */
abstract contract ERC721OwnerManagedExtension is
    IERC721OwnerManagedExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721AutoIdMinterExtension
{
    bool public managementPowerRevoked;

    function __ERC721OwnerManagedExtension_init() internal onlyInitializing {
        __ERC721OwnerManagedExtension_init_unchained();
    }

    function __ERC721OwnerManagedExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721OwnerManagedExtension).interfaceId);
    }

    /* ADMIN */

    function revokeManagementPower() external onlyOwner {
        managementPowerRevoked = true;
    }

    /* PUBLIC */

    /**
     * Override isApprovedForAll to allow owner to transfer tokens.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        if (!managementPowerRevoked) {
            if (operator == super.owner()) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, ERC721CollectionMetadataExtension)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }
}