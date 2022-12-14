// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../extensions/supply/ERC1155SupplyInternal.sol";
import "../../extensions/supply/ERC1155SupplyStorage.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "./ERC1155SupplyAdminStorage.sol";
import "./IERC1155SupplyAdmin.sol";

/**
 * @title ERC1155 - Supply - Admin - Ownable
 * @notice Allows owner of a EIP-1155 contract to change max supply of token IDs.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies IERC1155SupplyExtension
 * @custom:provides-interfaces IERC1155SupplyAdmin
 */
contract ERC1155SupplyOwnable is IERC1155SupplyAdmin, ERC1155SupplyInternal, OwnableInternal {
    using ERC1155SupplyStorage for ERC1155SupplyStorage.Layout;
    using ERC1155SupplyAdminStorage for ERC1155SupplyAdminStorage.Layout;

    function setMaxSupply(uint256 tokenId, uint256 newValue) public virtual onlyOwner {
        if (ERC1155SupplyAdminStorage.layout().maxSupplyFrozen[tokenId]) {
            revert ErrMaxSupplyFrozen();
        }

        _setMaxSupply(tokenId, newValue);
    }

    function setMaxSupplyBatch(uint256[] calldata tokenIds, uint256[] calldata newValues) public virtual onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (ERC1155SupplyAdminStorage.layout().maxSupplyFrozen[tokenIds[i]]) {
                revert ErrMaxSupplyFrozen();
            }
        }

        _setMaxSupplyBatch(tokenIds, newValues);
    }

    function freezeMaxSupply(uint256 tokenId) public virtual onlyOwner {
        ERC1155SupplyAdminStorage.layout().maxSupplyFrozen[tokenId] = true;
    }

    function freezeMaxSupplyBatch(uint256[] calldata tokenIds) public virtual onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC1155SupplyAdminStorage.layout().maxSupplyFrozen[tokenIds[i]] = true;
        }
    }

    /**
     * @dev Seta maximum amount of tokens possible to exist for a given token ID.
     */
    function _setMaxSupply(uint256 tokenId, uint256 newValue) internal {
        ERC1155SupplyStorage.layout().maxSupply[tokenId] = newValue;
    }

    /**
     * @dev Sets maximum amount of tokens possible to exist for multiple token IDs.
     */
    function _setMaxSupplyBatch(uint256[] calldata tokenIds, uint256[] calldata newValues) internal {
        mapping(uint256 => uint256) storage l = ERC1155SupplyStorage.layout().maxSupply;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            l[tokenIds[i]] = newValues[i];
        }
    }
}