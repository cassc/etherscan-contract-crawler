// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC1155Comet.sol";

/**
 * @title  ERC1155OperatorFilter
 *
 * @notice Implementation of the OpenSea OperatorFilter for ERC1155.
 *         This is now required to deploy a contract and receive
 *         royatlies when trading on OpenSea.
 */
abstract contract ERC1155OperatorFilter is
    ERC1155Comet,
    DefaultOperatorFilterer
{
    /**
     * @notice Approve `operator` to operate on all of `owner` tokens
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @notice See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}