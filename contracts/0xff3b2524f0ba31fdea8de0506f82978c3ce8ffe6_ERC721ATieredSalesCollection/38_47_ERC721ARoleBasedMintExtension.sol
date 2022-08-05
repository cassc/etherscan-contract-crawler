// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./ERC721AMinterExtension.sol";

import {IERC721RoleBasedMintExtension} from "../../ERC721/extensions/ERC721RoleBasedMintExtension.sol";

/**
 * @dev Extension to allow holders of a OpenZepplin-based role to mint directly.
 */
abstract contract ERC721ARoleBasedMintExtension is
    IERC721RoleBasedMintExtension,
    ERC165Storage,
    ERC721AMinterExtension,
    AccessControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function __ERC721ARoleBasedMintExtension_init(address minter)
        internal
        onlyInitializing
    {
        __ERC721ARoleBasedMintExtension_init_unchained(minter);
    }

    function __ERC721ARoleBasedMintExtension_init_unchained(address minter)
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721RoleBasedMintExtension).interfaceId);

        _setupRole(MINTER_ROLE, minter);
    }

    /* ADMIN */

    function mintByRole(address to, uint256 count) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "NOT_MINTER_ROLE");

        _mintTo(to, count);
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165Storage,
            AccessControl,
            ERC721ACollectionMetadataExtension
        )
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }
}