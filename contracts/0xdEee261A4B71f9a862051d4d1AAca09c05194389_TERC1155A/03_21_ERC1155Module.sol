// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

// OZ imports
import "../../openzeppelin-contracts-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import "../../openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
// Module imports
import "./AccessControlModule.sol";

/// @title Manage the ERC1155 implementation
contract ERC1155Module is
    ERC1155Upgradeable,
    ERC1155URIStorageUpgradeable,
    AccessControlModule
{
    /**
     * @dev Emitted when the value of 'baseUri' is set
     */
    event BaseURI(string newBaseURI);
    /**
     * @dev Emitted when the value of 'uri' is set
     */
    event DefaultURI(string newDefaultURI);

    /**
    @dev calls the different initialize functions from the different modules
    In AccessControlModule, we check that admin address is different from zero
    */
    function __ERC1155Impl_init(
        string memory uri_,
        address admin
    ) internal onlyInitializing {
        /* OpenZeppelin library */
        // OZ init_unchained functions are called first due to inheritance
        __Context_init_unchained();
        __ERC1155_init_unchained(uri_);
        __ERC1155URIStorage_init_unchained();
        // Access Control module
        __Ownable_init_unchained();
        __AccessControl_init_unchained();

        /* Module */
        __AccessControlModule_init_unchained(admin);

        /* own function */
        __ERC1155Module_init_unchained();
    }

    /**
     */
    function __ERC1155Module_init_unchained() internal onlyInitializing {
        // nothing to do
    }

    /********** MINT */

    /**
    @notice mint tokens for a specific owner
    */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        _mint(to, tokenId, amount, "");
    }

    /**
    @notice mint batch tokens for a specific owner
    */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, "");
    }

    /********** URI */

    function uri(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC1155URIStorageUpgradeable.uri(tokenId);
    }

    /**
    @notice Set the default URI for all tokens
    */
    function setDefaultURI(
        string memory newDefaultURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC1155Upgradeable._setURI(newDefaultURI);
        // We generate an event because the function _setUri does not do it
        emit DefaultURI(newDefaultURI);
    }

    /**
    @notice Set the URI for a given token
    */
    function setTokenURI(
        uint256 tokenId,
        string memory newTokenURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC1155URIStorageUpgradeable._setURI(tokenId, newTokenURI);
    }

    /**
    @notice Set the base URI, common for all tokens URI if the URI of the token is set
    */
    function setBaseURI(
        string memory newBaseURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(newBaseURI);
        // We generate an event because the function _setBaseURI does not do it
        emit BaseURI(newBaseURI);
    }

    /********** Interface */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControlUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return (ERC1155Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap;
}