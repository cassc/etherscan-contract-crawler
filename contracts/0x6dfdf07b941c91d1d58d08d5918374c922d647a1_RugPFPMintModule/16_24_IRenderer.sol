// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title IRenderer
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for a Renderer that returns the Uniform Resource Identifier (URI)
 * of a Collective NFT.
 */
interface IRenderer {
    /**
     * @return The URI of a particular Collective NFT
     * @param collective Address of the Collective
     * @param tokenId Token ID to render
     * @dev This function is intended for use by the front end, e.g. to render
     * a given token from a given Collective.
     */
    function tokenURIOf(address collective, uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @return The URI of a particular NFT from the calling Collective
     * @param tokenId Token ID to render
     * @dev This function is intended for use in ERC721Collective itself:
     * `msg.sender` is assumed to be the Collective. This allows external
     * contracts to access the URI of any of the Collective NFTs.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}