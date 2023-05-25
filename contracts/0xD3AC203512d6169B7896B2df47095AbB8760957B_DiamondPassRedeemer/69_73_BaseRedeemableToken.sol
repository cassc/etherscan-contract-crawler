// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";
import {IRedeemableToken} from "../interfaces/IRedeemableToken.sol";

/**
 * @notice Base implementation of a voucher token with approvable redeemer contracts.
 */
abstract contract BaseRedeemableToken is IRedeemableToken, AccessControlEnumerable {
    /**
     * @notice Authorised redeemers.
     */
    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    /**
     * @notice A role that cannot be granted or revoked.
     * @dev Used to lock in members of the `REDEEMER_ROLE` role.
     */
    bytes32 private constant _NOOP_ROLE = keccak256("NOOP_ROLE");

    constructor() {
        _setRoleAdmin(REDEEMER_ROLE, DEFAULT_STEERING_ROLE);
        _setRoleAdmin(_NOOP_ROLE, _NOOP_ROLE);
    }

    // =========================================================================
    //                           Redemption
    // =========================================================================

    /**
     * @notice Redeems a voucher token with given tokenId.
     * @dev Can only be called by approved redeemer contracts.
     * @dev Reverts if `sender` is not the owner of or approved to transfer the token.
     */
    function redeem(address sender, uint256 tokenId) external onlyRole(REDEEMER_ROLE) {
        if (!_isSenderAllowedToSpend(sender, tokenId)) {
            revert IRedeemableToken.RedeemerCallerNotAllowedToSpendVoucher(sender, tokenId);
        }

        _doRedeem(sender, tokenId);
    }

    // =========================================================================
    //                           Internal hooks
    // =========================================================================

    /**
     * @notice Hook called by `redeem` to check if the sender is allowed to
     * spend a given token (e.g. if it is the owner or transfer approved).
     */
    function _isSenderAllowedToSpend(address sender, uint256 tokenId) internal view virtual returns (bool result);

    /**
     * @notice Hook called by `redeem` to preform the redemption of a voucher
     * token (e.g. burn).
     */
    function _doRedeem(address sender, uint256 tokenId) internal virtual;

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Locks the `REDEEMER_ROLE` role.
     */
    function lockRedeemers() external onlyRole(DEFAULT_STEERING_ROLE) {
        _lockRedeemers();
    }

    /**
     * @notice Locks the `REDEEMER_ROLE` role.
     */
    function _lockRedeemers() internal {
        _setRoleAdmin(REDEEMER_ROLE, _NOOP_ROLE);
    }

    /**
     * @notice Revokes approval for all redeemers.
     */
    function _revokeAllRedeemers() internal {
        uint256 num = getRoleMemberCount(REDEEMER_ROLE);
        for (uint256 i = 0; i < num; i++) {
            // Akin to a popFront
            address redeemer = getRoleMember(REDEEMER_ROLE, 0);
            _revokeRole(REDEEMER_ROLE, redeemer);
        }
    }

    /**
     * @notice Overrides supportsInterface as required by inheritance.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable)
        returns (bool)
    {
        return interfaceId == type(IRedeemableToken).interfaceId || super.supportsInterface(interfaceId);
    }
}