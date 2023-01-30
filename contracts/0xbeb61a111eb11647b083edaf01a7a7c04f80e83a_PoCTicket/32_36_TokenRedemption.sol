// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

/**
 * @notice Encoding a redemption via a token.
 */
struct TokenRedemption {
    // The tokenId used for purchasing a ticket
    uint256 tokenId;
    // The number of tickets requested.
    uint256 num;
}

/**
 * @notice Utility library to work with `TokenRedemption`s.
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
library TokenRedemptionLib {
    error InvalidTokenOrder();

    /**
     * @notice Computes the total number of redemptions from a list of
     * `TokenRedemptions`.
     */
    function totalNum(TokenRedemption[] calldata redemptions)
        internal
        pure
        returns (uint256)
    {
        uint256 num;
        for (uint256 j; j < redemptions.length; ++j) {
            num += redemptions[j].num;
        }
        return num;
    }

    /**
     * @notice Checks if the tokenIds in a list of `TokenRedemptions` is
     * strictly monotonically increasing.
     * @dev Reverts otherwise
     */

    function checkStrictlyMonotonicallyIncreasing(
        TokenRedemption[] calldata redemptions
    ) internal pure {
        if (redemptions.length < 2) {
            return;
        }

        for (uint256 i = 0; i < redemptions.length - 1; ++i) {
            if (redemptions[i].tokenId >= redemptions[i + 1].tokenId) {
                revert InvalidTokenOrder();
            }
        }
    }
}