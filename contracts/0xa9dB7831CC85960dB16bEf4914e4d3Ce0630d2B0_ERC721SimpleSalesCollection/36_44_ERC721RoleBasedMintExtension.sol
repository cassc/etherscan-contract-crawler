// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./ERC721AutoIdMinterExtension.sol";

interface IERC721RoleBasedMintExtension {
    function mintByRole(address to, uint256 count) external;
}

/**
 * @dev Extension to allow holders of a OpenZepplin-based role to mint directly.
 */
abstract contract ERC721RoleBasedMintExtension is
    IERC721RoleBasedMintExtension,
    Initializable,
    ERC165Storage,
    ERC721AutoIdMinterExtension,
    AccessControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function __ERC721RoleBasedMintExtension_init(address minter)
        internal
        onlyInitializing
    {
        __ERC721RoleBasedMintExtension_init_unchained(minter);
    }

    function __ERC721RoleBasedMintExtension_init_unchained(address minter)
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
            ERC721CollectionMetadataExtension
        )
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }
}