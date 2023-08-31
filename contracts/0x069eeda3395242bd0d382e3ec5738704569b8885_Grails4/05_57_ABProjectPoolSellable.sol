// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {GenArt721CoreV3_Engine_Flex_PROOF} from "artblocks-contracts/GenArt721CoreV3_Engine_Flex_PROOF.sol";
import {ERC721A} from "ethier/erc721/ERC721ACommon.sol";

import {artblocksTokenID} from "proof/artblocks/TokenIDMapping.sol";
import {IGenArt721CoreContractV3_Mintable} from "proof/artblocks/IGenArt721CoreContractV3_Mintable.sol";

import {ProjectPoolSellable} from "./ProjectPoolSellable.sol";

/**
 * @title ArtBlocks enabled Project Pool Sellable
 * @notice A pool of sequentially indexed, sellable projects with ArtBlocks support and max supply
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 * @custom:reviewer Josh Laird (@jbmlaird)
 */
abstract contract ABProjectPoolSellable is ProjectPoolSellable {
    // =================================================================================================================
    //                          Constants
    // =================================================================================================================

    /**
     * @notice The ArtBlocks engine flex contract.
     */
    GenArt721CoreV3_Engine_Flex_PROOF public immutable flex;

    /**
     * @notice The ArtBlocks engine flex contract or a minter multiplexer.
     */
    IGenArt721CoreContractV3_Mintable public immutable flexMintGateway;

    // =================================================================================================================
    //                          Construction
    // =================================================================================================================

    constructor(
        Init memory init,
        GenArt721CoreV3_Engine_Flex_PROOF flex_,
        IGenArt721CoreContractV3_Mintable flexMintGateway_
    ) ProjectPoolSellable(init) {
        flex = flex_;
        flexMintGateway = flexMintGateway_;
    }

    // =================================================================================================================
    //                          Configuration
    // =================================================================================================================

    /**
     * @notice Returns true iff the project is a longform project.
     */
    function _isLongformProject(uint128 projectId) internal view virtual returns (bool);

    /**
     * @notice Returns the ArtBlocks engine project IDs for the longform projects.
     */
    function _artblocksProjectId(uint128 projectId) internal view virtual returns (uint256);

    // =================================================================================================================
    //                          Selling
    // =================================================================================================================

    /**
     * @notice Handles the minting of a token from a given project.
     * @dev Mints from the associated ArtBlocks project if the project is a longform project and locks the token in the
     * contract.
     */
    function _handleProjectMinted(uint256 tokenId, uint128 projectId, uint64 edition) internal virtual override {
        super._handleProjectMinted(tokenId, projectId, edition);

        if (_isLongformProject(projectId)) {
            flexMintGateway.mint_Ecf(address(this), _artblocksProjectId(projectId), address(this));
        }
    }

    // =================================================================================================================
    //                          Metadata
    // =================================================================================================================

    /**
     * @inheritdoc ERC721A
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        TokenInfo memory info = tokenInfo(tokenId);

        if (_isLongformProject(info.projectId)) {
            return flex.tokenURI(artblocksTokenID(_artblocksProjectId(info.projectId), info.edition));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @notice Helper function that returns true if the token belongs to a longform project.
     */
    function _isLongformToken(uint256 tokenId) internal view virtual returns (bool) {
        return _isLongformProject(tokenInfo(tokenId).projectId);
    }

    // =================================================================================================================
    //                          Inheritance resolution
    // =================================================================================================================

    // Artblocks does not permit partners to have operator filtering on any of their tokens (even if they are wrapped
    // like in this contract). We therefore selectively enable/disable the filtering based on the project type.

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override {
        if (_isLongformToken(tokenId)) {
            ERC721A.transferFrom(from, to, tokenId);
        } else {
            ProjectPoolSellable.transferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override {
        if (_isLongformToken(tokenId)) {
            ERC721A.safeTransferFrom(from, to, tokenId);
        } else {
            ProjectPoolSellable.safeTransferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override
    {
        if (_isLongformToken(tokenId)) {
            ERC721A.safeTransferFrom(from, to, tokenId, data);
        } else {
            ProjectPoolSellable.safeTransferFrom(from, to, tokenId, data);
        }
    }

    function approve(address operator, uint256 tokenId) public payable virtual override {
        if (_isLongformToken(tokenId)) {
            ERC721A.approve(operator, tokenId);
        } else {
            ProjectPoolSellable.approve(operator, tokenId);
        }
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        // Excluding any filtering here since `approvalForAll` will also affect Artblocks tokens.
        ERC721A.setApprovalForAll(operator, approved);
    }
}