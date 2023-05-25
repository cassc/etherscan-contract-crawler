// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./WrapperAdventureNFT.sol";
import "../opensea/operator-filter-registry/InitializableDefaultOperatorFilterer.sol";

/**
 * @title BlacklistedTransferWrapperAdventureNFT
 * @author Limit Break, Inc.
 * @notice Extends AdventureNFT, adding token wrapping and blacklisted transfer mechanisms.
 */
abstract contract BlacklistedTransferWrapperAdventureNFT is WrapperAdventureNFT, InitializableDefaultOperatorFilterer {

    function approve(address operator, uint256 tokenId) public virtual override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
}