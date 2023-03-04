// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc721/IArttacaERC721Upgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../../lib/LazyMint721.sol";

/**
 * @title Arttaca ERC721 interface, standard for Arttaca NFT collections.
 *
 * Contains the basic methods and functionalities that will be used for
 * Arttaca collections.
 */
interface IArttacaERC721Upgradeable is IERC721Upgradeable {

    struct TokenInformation {
        address owner;
        string tokenURI;
        Ownership.Royalties royalties;
    }

    function factoryAddress() external view returns (address);

    function contractURI() external view returns (string memory);

    /**
     * @dev Allows Owner to mint new assets in the collection.
     *
     * Requirements:
     *
     * - The `msg.sender` is the owner.
     * - The value '_to' must be different than a ZERO address.
     *
     * Emits a {Transfer} event for every new asset minted.
     */
    function mintAndTransferByOwner(address _to, uint _tokenId, string calldata _tokenURI, Ownership.Royalties memory _royalties) external;

    /**
     * @dev Allows anyone to mint assets if there's a valid owner signature.
     *
     * Requirements:
     *
     * - The `msg.sender` is the owner.
     * - The value '_to' must be different than a ZERO address.
     * - The value '_tokenData' must contain the token information.
     * - The value '_mintData' must contain valid signature with the expiration date.
     *
     * Emits a {Transfer} event for every new asset minted.
     */
    function mintAndTransfer(LazyMint721.TokenData calldata _tokenData, LazyMint721.MintData calldata _mintData) external;

    /**
     * @dev Get information about the token.
     *
     * Requirements:
     *
     * - The value '_tokenId' a valid & minted token id
     *
     * Returns a `TokenInformation` instance.
     */
    function getTokenInformation(uint _tokenId) external view returns (TokenInformation memory tokenInformation);
}