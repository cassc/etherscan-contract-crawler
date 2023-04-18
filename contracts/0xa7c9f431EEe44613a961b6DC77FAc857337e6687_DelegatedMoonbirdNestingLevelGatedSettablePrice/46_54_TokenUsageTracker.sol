// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {BitMaps} from "openzeppelin-contracts/utils/structs/BitMaps.sol";

import {TokenApprovalChecker} from "./TokenApprovalChecker.sol";

/**
 * @notice Checks if an operator is allowed to purchase with given ERC721 tokens and keeps track of already used tokens.
 */
abstract contract TokenUsageTracker is TokenApprovalChecker {
    using BitMaps for BitMaps.BitMap;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the operator is not allowed to act with a given token.
     */
    error OperatorNotAllowedToPurchaseWithToken(address operator, uint256 tokenId);

    /**
     * @notice Thrown if a token was already used to claim.
     */
    error TokenAlreadyUsedForPurchase(uint256 tokenId);

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The ERC721 contract for token-gating.
     */
    IERC721 internal immutable _token;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Keeps track of tokens that have already been used for redemptions.
     */
    BitMaps.BitMap private _usedTokens;

    constructor(IERC721 token) {
        _token = token;
    }

    // =========================================================================
    //                           Accounting
    // =========================================================================

    /**
     * @notice Checks if a token has already been used to purchase.
     */
    function alreadyPurchasedWithTokens(uint256[] calldata tokenIds) external view returns (bool[] memory) {
        bool[] memory used = new bool[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; ++i) {
            used[i] = _usedTokens.get(tokenIds[i]);
        }
        return used;
    }

    /**
     * @notice Checks if the operator is allowed to purchase with the given tokens and marks them as used.
     * @dev Reverts if the operator is not allowed to spend one or more of the listed tokens or if a token has already
     * been used.
     */
    function _checkAndTrackPurchasesWithTokens(address operator, uint256[] memory tokenIds) internal virtual {
        for (uint256 i; i < tokenIds.length; ++i) {
            if (!_isAllowedToPurchaseWithToken(operator, _token, tokenIds[i])) {
                revert OperatorNotAllowedToPurchaseWithToken(operator, tokenIds[i]);
            }

            if (_usedTokens.get(tokenIds[i])) {
                revert TokenAlreadyUsedForPurchase(tokenIds[i]);
            }
            _usedTokens.set(tokenIds[i]);
        }
    }
}