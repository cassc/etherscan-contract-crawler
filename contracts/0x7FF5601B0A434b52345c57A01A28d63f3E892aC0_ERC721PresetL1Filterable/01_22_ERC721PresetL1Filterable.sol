// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "operator-filter-registry/src/OperatorFilterer.sol";
import "./ERC721PresetL1.sol";

/// @dev This module is supposed to be used in Ethereum (settlement layer).

contract ERC721PresetL1Filterable is ERC721PresetL1, OperatorFilterer {
    // OpenSea Curated Subscription
    address public constant SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor(
        address bridgeAddress,
        string memory name,
        string memory symbol,
        string memory baseURI_
    )
        ERC721PresetL1(bridgeAddress, name, symbol, baseURI_)
        OperatorFilterer(SUBSCRIPTION, true)
    {}

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}