// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { ERC721Core } from "./ERC721Core.sol";

contract ERC721CoreOpenSea is ERC721Core, DefaultOperatorFilterer {
    /* solhint-disable no-empty-blocks */
    constructor(
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        uint96 royaltyFraction,
        uint256 newMaxSupply,
        string memory newTokenURIPrefix,
        string memory newTokenURISuffix
    )
        ERC721Core(
            name,
            symbol,
            royaltyReceiver,
            royaltyFraction,
            newMaxSupply,
            newTokenURIPrefix,
            newTokenURISuffix
        )
    {}

    /* solhint-enable no-empty-blocks */

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperatorApproval(to)
    {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }
}