// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {ERC721BaseInternal} from "./solidstate/ERC721BaseInternal.sol";
import {ScapesERC721MetadataStorage} from "./ScapesERC721MetadataStorage.sol";
import {IChild} from "./IChild.sol";
import {ScapesMerge} from "../metadata/ScapesMerge.sol";

import {ScapesMarketplaceStorage} from "./marketplace/ScapesMarketplaceStorage.sol";
import {IERC721MarketplaceInternal} from "./marketplace/IERC721MarketplaceInternal.sol";

/// @title MergeFacet
/// @author akuti.eth | scapes.eth
/// @notice This contract adds functionality to mint/burn merges.
/// @dev The facet adds merging to Scapes diamond contract.
contract MergeFacet is ERC721BaseInternal, IERC721MarketplaceInternal {
    error ScapesERC721__InvalidArgument();
    using ScapesMerge for ScapesMerge.Merge;

    uint256 internal constant MIN_MERGE_SIZE = 2;
    uint256 internal constant MAX_MERGE_SIZE = 8;

    /**
     * @notice Ceate and mint a merge out of multiple Scapes.
     * @dev Transfer Scape tokens to the contract and mint a merge Scape.
     * @param merge_ Merge settings
     */
    function merge(ScapesMerge.Merge memory merge_) external {
        _merge(merge_.toId(), merge_);
    }

    /**
     * @notice Ceate and mint a merge out of multiple Scapes.
     * @dev Transfer Scape tokens to the contract and mint a merge Scape.
     * @param mergeTokenId token Id of the merge
     */
    function merge(uint256 mergeTokenId) external {
        _merge(mergeTokenId, ScapesMerge.fromId(mergeTokenId));
    }

    /**
     * @notice Burn a merge and receive its Scapes.
     * @dev Burn the merge scape and transfer the contained Scapes form the contract.
     * @param merge_ Merge settings
     */
    function purge(ScapesMerge.Merge memory merge_) external {
        _purge(merge_.toId(), merge_);
    }

    /**
     * @notice Burn a merge and receive its Scapes.
     * @dev Burn the merge scape and transfer the contained Scapes form the contract.
     * @param mergeTokenId token Id of the merge
     */
    function purge(uint256 mergeTokenId) external {
        _purge(mergeTokenId, ScapesMerge.fromId(mergeTokenId));
    }

    function _merge(uint256 mergeTokenId, ScapesMerge.Merge memory merge_)
        internal
    {
        if (
            merge_.parts.length < MIN_MERGE_SIZE ||
            merge_.parts.length > MAX_MERGE_SIZE
        ) revert ScapesERC721__InvalidArgument();
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            // transfer all containing tokens, it is supposed to fail when tokens are repeated
            uint256 tokenId = merge_.parts[i].tokenId;
            if (!_isApprovedOrOwner(msg.sender, tokenId))
                revert ERC721Base__NotOwnerOrApproved();
            _transfer(msg.sender, address(this), tokenId);
        }
        _safeMint(msg.sender, mergeTokenId);
    }

    function _purge(uint256 mergeTokenId, ScapesMerge.Merge memory merge_)
        internal
    {
        if (_ownerOf(mergeTokenId) != msg.sender)
            revert ERC721Base__NotTokenOwner();
        if (mergeTokenId < 10_001) revert ScapesERC721__InvalidArgument();
        uint256 length = merge_.parts.length;
        _burn(mergeTokenId);
        for (uint256 i = 0; i < length; i++) {
            _safeTransfer(
                address(this),
                msg.sender,
                merge_.parts[i].tokenId,
                ""
            );
        }
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal) {
        if (
            from != address(0) &&
            ScapesMarketplaceStorage.layout().offers[tokenId].price > 0
        ) {
            ScapesMarketplaceStorage.Layout storage d = ScapesMarketplaceStorage
                .layout();
            d.offers[tokenId].price = 0;
            d.offers[tokenId].specificBuyer = address(0);
            emit OfferWithdrawn(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal) {
        IChild(ScapesERC721MetadataStorage.layout().scapeBound).update(
            from,
            to,
            tokenId
        );
        super._afterTokenTransfer(from, to, tokenId);
    }
}