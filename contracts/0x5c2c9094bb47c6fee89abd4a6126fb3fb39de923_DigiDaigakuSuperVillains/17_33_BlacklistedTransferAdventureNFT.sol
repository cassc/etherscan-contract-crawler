// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../adventures/AdventureNFT.sol";
import "../opensea/operator-filter-registry/InitializableDefaultOperatorFilterer.sol";

/**
 * @title BlacklistedTransferAdventureNFT
 * @author Limit Break, Inc.
 * @notice Extends AdventureNFT, adding whitelisted transfer mechanisms.
 */
abstract contract BlacklistedTransferAdventureNFT is AdventureNFT, InitializableDefaultOperatorFilterer {

    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public virtual override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}