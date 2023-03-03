// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {
    ERC721ACommon,
    BaseTokenURI,
    ERC721ACommonBaseTokenURI
} from "ethier/erc721/BaseTokenURI.sol";
import {BaseVoucherToken} from "./BaseVoucherToken.sol";

/**
 * @notice An ERC721 token intended to act as freely tradeable voucher.
 * @dev This is mainly a convenience wrapper.
 */
abstract contract ERC721VoucherBase is
    ERC721ACommonBaseTokenURI,
    BaseVoucherToken
{
    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Allows the contract owner to approve certain redeemers.
     */
    function setRedeemerApproval(address redeemer, bool toggle)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _setRedeemerApproval(redeemer, toggle);
    }

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
        return (sender == tokenOwner) || isApprovedForAll(tokenOwner, sender)
            || (sender == getApproved(tokenId));
    }

    /**
     * @notice Redeeming a voucher token burns it.
     */
    function _doRedeem(address, uint256 tokenId) internal virtual override {
        _burn(tokenId);
    }
}

contract ERC721Voucher is ERC721VoucherBase {
    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        address admin_,
        address steerer_,
        string memory name_,
        string memory symbol_,
        address payable royaltyReceiver_,
        uint96 royaltyBasisPoints_,
        string memory baseTokenURI_
    )
        ERC721ACommon(
            admin_,
            steerer_,
            name_,
            symbol_,
            royaltyReceiver_,
            royaltyBasisPoints_
        )
        BaseTokenURI(baseTokenURI_)
    {}
}