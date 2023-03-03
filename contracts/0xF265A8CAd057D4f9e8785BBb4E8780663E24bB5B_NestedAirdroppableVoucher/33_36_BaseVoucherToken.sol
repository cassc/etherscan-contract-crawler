// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IVoucherToken} from "../interfaces/IVoucherToken.sol";

/**
 * @notice Base implementation of a voucher token with approvable redeemer
 * contracts.
 */
abstract contract BaseVoucherToken is IVoucherToken {
    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The mapping of approved redeemers.
     */
    mapping(address => bool) private _isApprovedToRedeem;

    // =========================================================================
    //                           Redemption
    // =========================================================================

    /**
     * @notice Redeems a voucher token with given tokenId.
     * @dev Can only be called by approved redeemer contracts.
     * @dev Reverts if `sender` is not the owner of or approved to transfer
     * the token.
     */
    function redeem(address sender, uint256 tokenId) external {
        if (!_isSenderAllowedToSpend(sender, tokenId)) {
            revert IVoucherToken.RedeemerCallerNotAllowedToSpendVoucher(
                sender, tokenId
            );
        }

        if (!_isApprovedToRedeem[msg.sender]) {
            revert IVoucherToken.RedeemerNotApproved(msg.sender);
        }

        _doRedeem(sender, tokenId);
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    function _setRedeemerApproval(address redeemer, bool toggle) internal {
        _isApprovedToRedeem[redeemer] = toggle;
    }

    // =========================================================================
    //                           Virtual internal
    // =========================================================================

    /**
     * @notice Hook called by `redeem` to check if the sender is allowed to
     * spend a given token (e.g. if it is the owner or transfer approved).
     */
    function _isSenderAllowedToSpend(address sender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool result);

    /**
     * @notice Hook called by `redeem` to preform the redemption of a voucher
     * token (e.g. burn).
     */
    function _doRedeem(address sender, uint256 tokenId) internal virtual;
}