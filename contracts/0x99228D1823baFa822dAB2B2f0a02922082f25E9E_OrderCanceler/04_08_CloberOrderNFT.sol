// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./CloberOrderKey.sol";

interface CloberOrderNFT is IERC721, IERC721Metadata {
    /**
     * @notice Returns the base URI for the metadata of this NFT collection.
     * @return The base URI for the metadata of this NFT collection.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Returns the address of the market contract that manages this token.
     * @return The address of the market contract that manages this token.
     */
    function market() external view returns (address);

    /**
     * @notice Returns the address of contract owner.
     * @return The address of the contract owner.
     */
    function owner() external view returns (address);

    /**
     * @notice Called when a new token is minted.
     * @param to The receiver address of the minted token.
     * @param tokenId The id of the token minted.
     */
    function onMint(address to, uint256 tokenId) external;

    /**
     * @notice Called when a token is burned.
     * @param tokenId The id of the token burned.
     */
    function onBurn(uint256 tokenId) external;

    /**
     * @notice Changes the base URI for the metadata of this NFT collection.
     * @param newBaseURI The new base URI for the metadata of this NFT collection.
     */
    function changeBaseURI(string memory newBaseURI) external;

    /**
     * @notice Decodes a token id into an order key.
     * @param id The id to decode.
     * @return The order key corresponding to the given id.
     */
    function decodeId(uint256 id) external pure returns (OrderKey memory);

    /**
     * @notice Encodes an order key to a token id.
     * @param orderKey The order key to encode.
     * @return The id corresponding to the given order key.
     */
    function encodeId(OrderKey memory orderKey) external pure returns (uint256);

    /**
     * @notice Cancels orders with token ids.
     * @dev Only the OrderCanceler can call this function.
     * @param from The address of the owner of the tokens.
     * @param tokenIds The ids of the tokens to cancel.
     * @param receiver The address to send the underlying assets to.
     */
    function cancel(
        address from,
        uint256[] calldata tokenIds,
        address receiver
    ) external;
}