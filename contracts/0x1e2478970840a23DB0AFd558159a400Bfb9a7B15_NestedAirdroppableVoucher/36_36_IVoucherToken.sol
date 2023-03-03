// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.0;

/**
 * @notice Interface for a redeemable Voucher token preventing double spending
 * through internal book-keeping (e.g. burning the token, token property, etc.).
 * @dev Voucher tokens are intendent to be redeemed through a redeemer contract.
 */
interface IVoucherToken {
    /**
     * @notice Thrown if the redemption caller is not allowed to spend a given
     * voucher.
     */
    error RedeemerCallerNotAllowedToSpendVoucher(
        address sender, uint256 tokenId
    );

    /**
     * @notice Thrown if a redeemer contract is not allowed to redeem this
     * voucher.
     */
    error RedeemerNotApproved(address);

    /**
     * @notice Interface through which a `IRedeemer` contract informs the
     * voucher about its redemption.
     * @param sender The address that initiate the redemption on the
     * redeemer contract.
     * @param tokenId The voucher token to be redeemed.
     * @dev This function MUST be called by redeemer contracts.
     * @dev MUST revert with `RedeemerNotApproved` if the calling redeemer
     * contract is not approved to spend this voucher.
     * @dev MUST revert with `RedeemerCallerNotAllowedToSpendVoucher` if
     * sender is not allowed to spend tokenId.
     */
    function redeem(address sender, uint256 tokenId) external;
}