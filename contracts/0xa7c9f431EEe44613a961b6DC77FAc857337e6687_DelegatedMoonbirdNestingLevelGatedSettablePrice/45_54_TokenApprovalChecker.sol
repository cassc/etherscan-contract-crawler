// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IDelegationRegistry} from "delegation-registry/IDelegationRegistry.sol";

/**
 * @notice Checks if an operator is allowed to purchase with given ERC721 tokens.
 */
abstract contract TokenApprovalChecker {
    /**
     * @notice Determines if a given operator is allowed to purchase with a given token.
     */
    function _isAllowedToPurchaseWithToken(address operator, IERC721 token, uint256 tokenId)
        internal
        view
        virtual
        returns (bool);
}

/**
 * @notice Allows the token owner and any ERC721-approved operator to purchase.
 */
contract DefaultTokenApprovalChecker is TokenApprovalChecker {
    /**
     * @inheritdoc TokenApprovalChecker
     */
    function _isAllowedToPurchaseWithToken(address operator, IERC721 token, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        address tokenOwner = token.ownerOf(tokenId);
        return (operator == tokenOwner) || token.isApprovedForAll(tokenOwner, operator)
            || (operator == token.getApproved(tokenId));
    }
}

/**
 * @notice Extension to `DefaultTokenApprovalChecker` that additionally allows delegated operators via delegate.cash.
 */
contract DelegatedTokenApprovalChecker is TokenApprovalChecker {
    /**
     * @notice The delegate.cash delegation registry.
     */
    IDelegationRegistry internal immutable _delegationRegistry;

    constructor(IDelegationRegistry delegationRegistry) {
        _delegationRegistry = delegationRegistry;
    }

    /**
     * @inheritdoc TokenApprovalChecker
     */
    function _isAllowedToPurchaseWithToken(address operator, IERC721 token, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        // Reimplemententing the standard checks instead of calling
        // `super._isAllowedToClaim` here to have a specific ordering for gas
        // efficiency: 1. owner, 2. delegation, 3. ERC721 approvals.
        address tokenOwner = token.ownerOf(tokenId);
        return (operator == tokenOwner)
            || _delegationRegistry.checkDelegateForToken(operator, tokenOwner, address(token), tokenId)
            || token.isApprovedForAll(tokenOwner, operator) || (operator == token.getApproved(tokenId));
    }
}