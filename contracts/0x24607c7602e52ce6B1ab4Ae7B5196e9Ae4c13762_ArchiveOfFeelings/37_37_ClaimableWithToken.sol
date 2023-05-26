// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
 * @notice Introduces claimability based on ERC721 token ownership.
 */
abstract contract ClaimableWithToken {
    using BitMaps for BitMaps.BitMap;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the caller is not allowed to act with a given token.
     */
    error CallerNotAllowedToClaimWithToken(uint256 tokenId);

    /**
     * @notice Thrown if a token was already used to claim.
     */
    error TokenAlreadyUsedForClaim(uint256 tokenId);

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
     * @notice Keeps track of tokens that have already been used for
     * redemptions.
     */
    BitMaps.BitMap private _usedTokens;

    constructor(IERC721 token) {
        _token = token;
    }

    // =========================================================================
    //                           Claiming
    // =========================================================================

    /**
     * @notice Checks if a token has already been used to claim.
     */
    function alreadyClaimedWithToken(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _usedTokens.get(tokenId);
    }

    /**
     * @notice Redeems claims with a list of given token ids.
     * @dev Reverts if the sender is not allowed to spend one or more of the
     * listed tokens or if a token has already been used.
     */
    function claimWithTokens(uint256[] calldata tokenIds)
        external
        payable
        virtual
    {
        _beforeClaimWithTokens(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; ++i) {
            if (!_isAllowedToClaim(msg.sender, tokenIds[i])) {
                revert CallerNotAllowedToClaimWithToken(tokenIds[i]);
            }

            if (alreadyClaimedWithToken(tokenIds[i])) {
                revert TokenAlreadyUsedForClaim(tokenIds[i]);
            }
            _usedTokens.set(tokenIds[i]);
        }

        _doClaimFromTokens(msg.sender, tokenIds.length);
    }

    /**
     * @notice Hook called by `claimWithTokens` before claiming from tokens.
     * @dev Intended to add more checks required by the inheriting contract
     * (e.g. total claim limit).
     */
    function _beforeClaimWithTokens(
        address receiver,
        uint256[] calldata tokenIds
    ) internal virtual {}

    /**
     * @notice Determines if a given operator is allowed to claim from a given
     * token.
     * @dev by default either the token owner or ERC721 approved operators.
     */
    function _isAllowedToClaim(address operator, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address tokenOwner = _token.ownerOf(tokenId);
        return (operator == tokenOwner)
            || (operator == _token.getApproved(tokenId))
            || _token.isApprovedForAll(tokenOwner, operator);
    }

    /**
     * @notice Hook called by `claimWithTokens` to preform the actual claim.
     * @dev This is intended be implemented by the inheriting contract, e.g.
     * minting a token.
     */
    function _doClaimFromTokens(address receiver, uint256 numClaims)
        internal
        virtual;
}