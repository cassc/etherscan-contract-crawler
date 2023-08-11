// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  IRenderMetadata
 * @author slvrfn
 * @dev    External interface of RenderMetadataFacet declared to allow calls from other facets
 */
interface IRenderMetadata {
    /**
     * @notice Renders metadata for a Relic.
     * @dev    Bytes used here to allow for potential future iterations to pass different data required for rendering.
     * @param  tokenId - the tokenId associated with this seed update.
     * @param  data - Encoded data for use in rendering Relic metadata.
     */
    function renderMetadata(uint256 tokenId, bytes memory data) external view returns (string memory metadata);
}