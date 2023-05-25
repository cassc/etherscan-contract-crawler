// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {SafeCast} from "openzeppelin-contracts/utils/math/SafeCast.sol";

import {InternallyPriced} from "../base/InternallyPriced.sol";
import {TokenUsageTracker} from "../base/TokenUsageTracker.sol";

/**
 * @notice Introduces claimability based on ERC721 token ownership.
 */
abstract contract InternallyPricedTokenGated is InternallyPriced, TokenUsageTracker {
    constructor(IERC721 token) TokenUsageTracker(token) {}

    /**
     * @notice Redeems claims with a list of given token ids.
     * @dev Reverts if the sender is not allowed to spend one or more of the
     * listed tokens or if a token has already been used.
     */
    function _purchase(uint256[] memory tokenIds) internal virtual {
        TokenUsageTracker._checkAndTrackPurchasesWithTokens(msg.sender, tokenIds);
        InternallyPriced._purchase(msg.sender, SafeCast.toUint64(tokenIds.length), "");
    }
}