// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {BitMaps} from "openzeppelin-contracts/utils/structs/BitMaps.sol";
import {SafeCast} from "openzeppelin-contracts/utils/math/SafeCast.sol";
import {IDelegationRegistry} from "delegation-registry/IDelegationRegistry.sol";

import {InternallyPricedTokenGated} from "../base/InternallyPricedTokenGated.sol";
import {
    TokenApprovalChecker,
    DefaultTokenApprovalChecker,
    DelegatedTokenApprovalChecker
} from "../base/TokenApprovalChecker.sol";

/**
 * @notice Introduces claimability based on ERC721 token ownership.
 */
abstract contract TokenGated is InternallyPricedTokenGated {
    constructor(IERC721 token) InternallyPricedTokenGated(token) {}

    /**
     * @notice Redeems claims with a list of given token ids.
     * @dev Reverts if the sender is not allowed to spend one or more of the listed tokens or if a token has already
     * been used.
     */
    function purchase(uint256[] calldata tokenIds) external payable virtual {
        InternallyPricedTokenGated._purchase(tokenIds);
    }
}

/**
 * @notice Introduces claimability based on ERC721 token ownership.
 */
abstract contract DefaultTokenGated is TokenGated, DefaultTokenApprovalChecker {
    constructor(IERC721 token) TokenGated(token) {}

    /**
     * @inheritdoc TokenApprovalChecker
     */
    function _isAllowedToPurchaseWithToken(address operator, IERC721 token, uint256 tokenId)
        internal
        view
        virtual
        override(TokenApprovalChecker, DefaultTokenApprovalChecker)
        returns (bool)
    {
        return DefaultTokenApprovalChecker._isAllowedToPurchaseWithToken(operator, token, tokenId);
    }
}

/**
 * @notice Extension to `TokenGated` adding delegation via delegate.cash.
 */
abstract contract DelegatedTokenGated is TokenGated, DelegatedTokenApprovalChecker {
    constructor(IERC721 token, IDelegationRegistry delegationRegistry)
        TokenGated(token)
        DelegatedTokenApprovalChecker(delegationRegistry)
    {}

    /**
     * @inheritdoc TokenApprovalChecker
     */
    function _isAllowedToPurchaseWithToken(address operator, IERC721 token, uint256 tokenId)
        internal
        view
        virtual
        override(TokenApprovalChecker, DelegatedTokenApprovalChecker)
        returns (bool)
    {
        return DelegatedTokenApprovalChecker._isAllowedToPurchaseWithToken(operator, token, tokenId);
    }
}