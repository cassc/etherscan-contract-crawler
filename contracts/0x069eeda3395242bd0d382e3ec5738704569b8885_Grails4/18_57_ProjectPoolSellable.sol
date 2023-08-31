// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {ERC721A, ERC721ACommon, BaseTokenURI, ERC721ACommonBaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";
import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";

import {SellableERC721ACommon} from "proof/sellers/sellable/SellableERC721ACommon.sol";
import {SellableERC721ACommonByProjectID} from "proof/sellers/sellable/SellableERC721ACommonByProjectID.sol";

/**
 * @title Project Pool Sellable
 * @notice A pool of sequentially indexed, sellable projects with max supply
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 * @custom:reviewer Josh Laird (@jbmlaird)
 */
abstract contract ProjectPoolSellable is
    ERC721ACommonBaseTokenURI,
    OperatorFilterOS,
    SellableERC721ACommonByProjectID
{
    // =================================================================================================================
    //                          Errors
    // =================================================================================================================

    /**
     * @notice Thrown if a user attempts to purchase tokens from an exhausted project.
     */
    error ProjectExhausted(uint128 projectId);

    /**
     * @notice Thrown if a user attempts to purchase tokens from an invalid project.
     */
    error InvalidProject(uint128 projectId);

    // =================================================================================================================
    //                          Construction
    // =================================================================================================================

    struct Init {
        address admin;
        address steerer;
        string name;
        string symbol;
        string baseURI;
        address payable royaltyReciever;
        uint96 royaltyBasisPoints;
    }

    constructor(Init memory init)
        ERC721ACommon(init.admin, init.steerer, init.name, init.symbol, init.royaltyReciever, init.royaltyBasisPoints)
        BaseTokenURI(init.baseURI)
    {}

    // =================================================================================================================
    //                          Configuration
    // =================================================================================================================

    /**
     * @notice Returns the number of available project.
     * @dev Intended to be implemented by the inheriting contract.
     */
    function _numProjects() internal view virtual returns (uint128);

    /**
     * @notice Returns the number of tokens than can be minted per project.
     * @param projectId The project ID in `[0, _numProjects())`.
     * @dev Intended to be implemented by the inheriting contract.
     */
    function _maxNumPerProject(uint128 projectId) internal view virtual returns (uint64);

    // =================================================================================================================
    //                          Selling
    // =================================================================================================================

    /**
     * @inheritdoc SellableERC721ACommonByProjectID
     * @dev Ensures that the configured project bounds are not exceeded.
     */
    function _handleProjectMinted( /* tokenId */ uint256, uint128 projectId, uint64 edition)
        internal
        virtual
        override
    {
        if (projectId >= _numProjects()) {
            revert InvalidProject(projectId);
        }

        if (edition >= _maxNumPerProject(projectId)) {
            revert ProjectExhausted(projectId);
        }
    }

    // =================================================================================================================
    //                          Metadata
    // =================================================================================================================

    /**
     * @notice Returns all tokenIds for a given project.
     * @dev Intended for front-end consumption and not optimised for gas.
     */
    function tokenIdsByProjectId(uint128 projectId) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](numPurchasedPerProject(projectId));

        uint256 cursor;
        uint256 supply = totalSupply();
        for (uint256 tokenId = 0; tokenId < supply; ++tokenId) {
            if (tokenInfo(tokenId).projectId == projectId) {
                tokenIds[cursor++] = tokenId;
            }
        }

        return tokenIds;
    }

    /**
     * @notice Returns the number of tokens purchased for each project.
     * @dev Intended for front-end consumption and not optimised for gas.
     */
    function numPurchasedPerProject() external view returns (uint64[] memory) {
        uint128 num = _numProjects();
        uint64[] memory numPurchased = new uint64[](num);
        for (uint128 i = 0; i < num; i++) {
            numPurchased[i] = numPurchasedPerProject(i);
        }
        return numPurchased;
    }

    // =================================================================================================================
    //                          Inheritance resolution
    // =================================================================================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, ERC721ACommonBaseTokenURI, SellableERC721ACommon)
        returns (bool)
    {
        return ERC721ACommonBaseTokenURI.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override(ERC721A, ERC721ACommonBaseTokenURI) returns (string memory) {
        return ERC721ACommonBaseTokenURI._baseURI();
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId, data);
    }
}