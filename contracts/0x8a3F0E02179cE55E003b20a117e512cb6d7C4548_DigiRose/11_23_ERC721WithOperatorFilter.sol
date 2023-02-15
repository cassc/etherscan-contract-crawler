// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./DefaultOperatorFilterer.sol";
import "./ERC721RoyaltyOwnable.sol";

/**
 * @dev ERC721 with Default OperatorFilter provided by OpenSEA
 *
 *      ERC721WithOperatorFilter
 *          <= ERC721RoyaltyOwnable
 *          <= ERC721Royalty
 *          <= ERC721Enumerable
 *          <= ERC721
 */
abstract contract ERC721WithOperatorFilter is
    DefaultOperatorFilterer,
    ERC721RoyaltyOwnable
{
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
