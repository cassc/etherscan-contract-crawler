// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// @notice Interface for Polygon bridgable NFTs on L1-chain
interface IERC721BridgableParent is IERC721Enumerable {
    /**
     * Mints a token. Can be called by minting contract or by bridge
     *
     * @param to         Account to mint to
     * @param tokenId    Id of token to mint
     */
    function mint(address to, uint256 tokenId) external;

    /**
     * Mints a token and also sets metadata from L2
     *
     * @param to        Address to mint to
     * @param tokenId   Id of the token to mint
     * @param metadata  ABI encoded tokenURI for the token
     */
    function mint(
        address to,
        uint256 tokenId,
        bytes calldata metadata
    ) external;

    /**
     * @param tokenId token id to check
     * @return Whether or not the given tokenId has been minted
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * Sets the metadata for a given token, only callable by bridge
     *
     * @param tokenId  Id of the token to set metadata for
     * @param data     Metadata for the token
     */
    function setTokenMetadata(uint256 tokenId, bytes calldata data) external;
}