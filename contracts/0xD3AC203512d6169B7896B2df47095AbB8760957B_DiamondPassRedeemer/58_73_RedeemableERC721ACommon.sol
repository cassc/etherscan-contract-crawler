// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {ERC721ACommon} from "ethier/erc721/ERC721ACommon.sol";
import {BaseRedeemableToken} from "./BaseRedeemableToken.sol";

/**
 * @notice An ERC721 token intended to act as freely tradeable voucher.
 * @dev This is mainly a convenience wrapper.
 */
abstract contract RedeemableERC721ACommon is BaseRedeemableToken, ERC721ACommon {
    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Allows spending if the sender is the owner of or approved for
     * transfers of a given token.
     */

    function _isSenderAllowedToSpend(address sender, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool result)
    {
        address tokenOwner = ownerOf(tokenId);
        return (sender == tokenOwner) || isApprovedForAll(tokenOwner, sender) || (sender == getApproved(tokenId));
    }

    /**
     * @notice Redeeming a voucher token burns it.
     */
    function _doRedeem(address, uint256 tokenId) internal virtual override {
        _burn(tokenId);
    }

    /**
     * @notice Overrides supportsInterface as required by inheritance.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseRedeemableToken, ERC721ACommon)
        returns (bool)
    {
        return BaseRedeemableToken.supportsInterface(interfaceId) || ERC721ACommon.supportsInterface(interfaceId);
    }
}