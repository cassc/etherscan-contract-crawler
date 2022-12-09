//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/ICollection.sol";

/**
 * Contract for an ERC-721 collection.
 * @custom:security-contact [email protected]
 */
contract Collection is
    ICollection,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Royalty,
    ERC721Burnable,
    AccessControl,
    ReentrancyGuard
{
    /*********/
    /* Types */
    /*********/

    /**
     * Constant used for representing the minter role.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /***************/
    /* Constructor */
    /***************/

    /**
     * Creates a new instance of this contract.
     *
     * @param name_ The ERC-721 name of this collection.
     * @param symbol_ The ERC-721 symbol of this collection.
     * @param creator The creator address that will be given the default admin
     *     role.
     * @param marketplace The marketplace address that will be given the minter
     *     role.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address creator,
        address marketplace
    ) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, creator);
        _grantRole(MINTER_ROLE, marketplace);
    }

    /**********************/
    /* External functions */
    /**********************/

    /**
     * Mints a new token and transfers it to the receiver.
     *
     * Assigns a token id, token URI, royalty receiver and royalty numerator
     *
     * @param tokenReceiver The address that should receive the token.
     * @param tokenId The token id of the token.
     * @param tokenURI_ The token URI of the token.
     * @param royaltyReceiver The royalty receiver of the token.
     * @param royaltyNumerator The royalty numerator of the token.
     */
    function mintToken(
        address tokenReceiver,
        uint256 tokenId,
        string calldata tokenURI_,
        address royaltyReceiver,
        uint16 royaltyNumerator
    ) external nonReentrant onlyRole(MINTER_ROLE) {
        _safeMint(tokenReceiver, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        _setTokenRoyalty(tokenId, royaltyReceiver, royaltyNumerator);
    }

    /********************/
    /* Public functions */
    /********************/

    /**
     * Returns whether or not the given ERC-165 interface id is supported.
     *
     * This function is implemented in multiple parent contracts and is only
     * overridden here to resolve inheritance linearization.
     *
     * @param interfaceId The ERC-165 interface id to check if it is supported.
     * @return True if the interface id is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Returns the token URI for the given token id.
     *
     * This function is implemented in multiple parent contracts and is only
     * overridden here to resolve inheritance linearization.
     *
     * @param tokenId The token id to retrieve the token URI for.
     * @return The token URI for the given token id.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**********************/
    /* Internal functions */
    /**********************/

    /**
     * Hook method that can be overridden to add additional business logic
     * before a token is transferred.
     *
     * This function is implemented in multiple parent contracts and is only
     * overridden here to resolve inheritance linearization.
     *
     * @param from The address the token is about to be transferred from.
     * @param to The address the token is about to be transferred to.
     * @param tokenId The token id of the token that is about to be
     *     transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * Burns the token for the given token id.
     *
     * This function is implemented in multiple parent contracts and is only
     * overridden here to resolve inheritance linearization.
     *
     * @param tokenId The token id to retrieve the token URI for.
     */
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }
}