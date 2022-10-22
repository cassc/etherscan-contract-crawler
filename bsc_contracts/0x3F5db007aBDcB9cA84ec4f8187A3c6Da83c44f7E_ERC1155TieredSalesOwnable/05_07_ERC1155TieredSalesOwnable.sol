// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../access/ownable/OwnableInternal.sol";
import "./ERC1155TieredSalesStorage.sol";
import "./IERC1155TieredSalesAdmin.sol";

/**
 * @title ERC1155 - Tiered Sales - Admin - Ownable
 * @notice Used to manage which ERC1155 token is related to which the sales tier.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies IERC1155TieredSales
 * @custom:provides-interfaces IERC1155TieredSalesAdmin
 */
contract ERC1155TieredSalesOwnable is IERC1155TieredSalesAdmin, OwnableInternal {
    using ERC1155TieredSalesStorage for ERC1155TieredSalesStorage.Layout;

    function configureTierTokenId(uint256 tierId, uint256 tokenId) external virtual onlyOwner {
        ERC1155TieredSalesStorage.layout().tierToTokenId[tierId] = tokenId;
    }

    function configureTierTokenId(uint256[] calldata tierIds, uint256[] calldata tokenIds) external virtual onlyOwner {
        require(
            tierIds.length == tokenIds.length,
            "ERC1155TieredSalesOwnable: tierIds and tokenIds must be same length"
        );

        for (uint256 i = 0; i < tierIds.length; i++) {
            ERC1155TieredSalesStorage.layout().tierToTokenId[tierIds[i]] = tokenIds[i];
        }
    }
}