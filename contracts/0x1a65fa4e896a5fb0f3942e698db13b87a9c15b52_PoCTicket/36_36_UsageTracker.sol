// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {TokenRedemption} from "poc-ticket/TokenRedemption.sol";

/**
 * @title Proof of Conference Tickets - PROOF token usage tracker (for ticket
 * purchases)
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
contract UsageTracker {
    mapping(IERC721 => mapping(uint256 => uint256)) private _numTokenUsed;

    function _trackTokenUsage(
        IERC721 token,
        TokenRedemption[] calldata redemptions
    ) internal {
        for (uint256 i; i < redemptions.length; ++i) {
            _numTokenUsed[token][redemptions[i].tokenId] += redemptions[i].num;
        }
    }

    /**
     * @notice Checks how often a given token was used to redeem a ticket.
     */
    function numTokenUsed(IERC721 token, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _numTokenUsed[token][tokenId];
    }
}