// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

// OZ imports
import "../../openzeppelin-contracts-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import "../../openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
// Module imports
import "./AccessControlModule.sol";

/// @title Manage the ERC1155 implementation
contract ERC1155Module is ERC1155Upgradeable, ERC1155URIStorageUpgradeable , AccessControlModule {
    /**
     * @dev Emitted when the value of 'baseUri' is set
     */
    event BaseURISet(string indexed newBaseURIIndexed, string newBaseURI);
    /**
     * @dev Emitted when the value of 'uri' is set
     */
    event DefaultURISet(string indexed newDefaultURIIndexed, string newDefaultURI);
    
    /**
    @dev calls the different initialize functions from the different modules
    */
    function __ERC1155Impl_init(string memory uri_) internal onlyInitializing {
        /* OpenZeppelin library */
        // OZ init_unchained functions are called first due to inheritance
        __Context_init_unchained();
        __ERC1155_init_unchained(uri_);
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
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

    function uri(uint256 tokenId) public view virtual override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) returns (string memory) {
        return ERC1155URIStorageUpgradeable.uri(tokenId);
    }

    /**
    @notice Set the default URI for all tokens
    */
    function setDefaultURI(string memory newDefaultURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC1155Upgradeable._setURI(newDefaultURI);
        // We generate an event because the function _setUri does not do it
        emit DefaultURISet(newDefaultURI, newDefaultURI);
    }

    /**
    @notice Set the URI for a given token
    */
    function setTokenURI(uint256 tokenId, string memory newTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC1155URIStorageUpgradeable._setURI(tokenId, newTokenURI);
    }

    /**
    @notice Set the base URI, common for all tokens URI if the URI of the token is set
    */
    function setBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE){
        _setBaseURI(newBaseURI);
        // We generate an event because the function _setBaseURI does not do it
        emit BaseURISet(newBaseURI, newBaseURI);
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

    uint256[50] private __gap;
}