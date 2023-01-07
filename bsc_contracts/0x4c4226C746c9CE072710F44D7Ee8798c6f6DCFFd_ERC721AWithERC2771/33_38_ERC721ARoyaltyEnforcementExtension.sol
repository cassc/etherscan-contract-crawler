// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../finance/royalty/RoyaltyEnforcementInternal.sol";
import "../../base/ERC721ABase.sol";

abstract contract ERC721ARoyaltyEnforcementExtension is RoyaltyEnforcementInternal, ERC721ABase {
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        _setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override onlyAllowedOperatorApproval(to) {
        _approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyAllowedOperator(from) {
        _safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override onlyAllowedOperator(from) {
        _safeTransferFrom(from, to, tokenId, data);
    }
}