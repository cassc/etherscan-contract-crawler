// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IndieV1Errors {
    /* --------------------------- Ownership -------------------------- */

    /**
     * @dev Reverts when attempting to grant owner role instead of transfer
     */
    error CannotGrantRoleOwner();

    /**
     * @dev Reverts when attempting to revoke owner role instead of renouce
     */
    error CannotRevokeRoleOwner();

    /**
     * @dev (Deprecated) Reverts when attempting to transfer owner to admin
     */
    error CannotTransferOwnershipToAdminRole();

    /**
     * @dev Reverts when attempting to transfer owner to the same address
     */
    error CannotTransferOwnershipToSelf();

    /* --------------------------- Membership Claim -------------------------- */

    /**
     * @dev Reverts when the merkle root if membership claiming is empty
     */
    error MembershipClaimDisabled();

    /**
     * @dev Reverts when the tokens a membership has already been claimed
     */
    error MembershipAlreadyClaimed();

    /**
     * @dev Reverts when the amount or account cannot be verified
     */
    error UnableToVerifyClaim();

    /* --------------------------- Member Status -------------------------- */

    /**
     * @dev Reverts when attempting to set status for an address that owns no tokens
     */
    error CannotSetMemberStatusForNonMember();

    /**
     * @dev Reverts when attempting to unset status for a member
     */
    error CannotUnsetMemberStatus();

    /**
     * @dev Reverts when attempting to liquidate with an unexpected status
     */
    error CannotLiquidateUnlessResignOrTerminate();

    /**
     * @dev Reverts when attempting to set status for a member as resigned
     */
    error CannotSetMemberStatusAsResigned();

    /**
     * @dev Reverts when attempting resign with dividends not yet claimed
     */
    error CannotResignWhenUnclaimedDividends();

    /**
     * @dev Reverts when attempting to set status for a member as terminated
     */
    error CannotSetMemberStatusAsTerminated();

    /* --------------------------- Withholding -------------------------- */

    /**
     * @dev Reverts when attempting to set withholding percentage for a non member
     */
    error CannotSetIndieWithholdingForNonMember();

    /**
     * @dev Reverts when attempting to set withholding percentage for a non member
     */
    error WithholdingPercentageExceedsMaximum();

    /* --------------------------- Seasonal Mint -------------------------- */

    /**
     * @dev Reverts when attempting to mint tokens to a non-member
     */
    error CannotMintToNonMember();

    /**
     * @dev Reverts when minting zero tokens
     */
    error CannotMintZeroTokens();

    /**
     * @dev Reverts when minting tokens will exceed the max supply
     */
    error MintExceedsMaxSupply();

    /* --------------------------- Seasonal Snapshot -------------------------- */

    /**
     * @dev Reverts when the dividend amount is less than one USDC
     */
    error SeasonalDividendAmountTooSmall();

    /**
     * @dev Reverts when contract does not possess enough USDC to create the requested seasonal snapshot
     */
    error InsufficentFundsToCreateSeasonalSnapshot();

    /**
     * @dev Reverts when a non-member is included in the requested seasonal snapshot
     */
    error NonMemberIncludedInSeasonalSnapshot();

    /**
     * @dev Reverts when a member is listed twice in the requested seasonal snapshot
     */
    error MemberDuplicatedInSeasonalSnapshot();

    /**
     * @dev Reverts when season id is zero or beyond most recent
     */
    error SeasonIdOutOfRange();

    /* --------------------------- Dividends -------------------------- */

    /**
     * @dev Reverts when attempting to claim dividends when not an active member
     */
    error CannotClaimDividendsWhenNotActive();

    /**
     * @dev Reverts when attempting to claim dividends when there are none
     */
    error CannotClaimZeroDividends();

    /**
     * @dev Reverts when attempting to claim dividends more than once
     */
    error DividendsAlreadyClaimed();

    /* --------------------------- Transfer -------------------------- */

    /**
     * @dev Reverts when attempting to transfer tokens between members
     */
    error MemberToMemberTokenTransfersAreNotAllowed();

    /* --------------------------- Withdrawal -------------------------- */

    /**
     * @dev Reverts when attempting to withdraw funds to a disallowed address
     */
    error WithdrawRecipientInvalid();

    /**
     * @dev Reverts when attempting to withdraw more funds than available, or zero or less
     */
    error WithdrawAmountOutOfRange();

    /* --------------------------- Generic -------------------------- */

    /**
     * @dev Reverts when two or more arrays that should be of equal length and are not
     */
    error UnequalArrayLengths();

    /**
     * @dev Reverts when an array contains too many items
     */
    error ArrayTooLarge();

    /**
     * @dev Reverts when a divide by zero error would occur
     */
    error DivideByZero();

    /**
     * @dev Reverts when attempting to use the zero address
     */
    error ZeroAddress();
}