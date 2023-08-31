//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoServicerEvents is an interface that defines all events emitted by the Term Repo Servicer.
interface ITermRepoServicerEvents {
    /// @notice Event emitted when a Term Loan Manager is initialized.
    /// @param termRepoId A Term Repo id
    /// @param purchaseToken The address of purchase token used for loans and repay
    /// @param maturityTimestamp The timestamp at which term reaches maturity
    /// @param endOfRepurchaseWindow The timestamp at which Term Repo is closed to repurchase
    /// @param redemptionTimestamp The timestamp at which loaners can redeem term repo tokens
    /// @param servicingFee percentage share of bid amounts charged to bidder
    /// @param version The version tag of the smart contract deployed
    event TermRepoServicerInitialized(
        bytes32 termRepoId,
        address termRepoServicer,
        address purchaseToken,
        uint256 maturityTimestamp,
        uint256 endOfRepurchaseWindow,
        uint256 redemptionTimestamp,
        uint256 servicingFee,
        string version
    );

    /// @notice Event emitted when a TermRepoLocker is reopened to another auction group
    /// @param termRepoId A Term Repo id
    /// @param termRepoServicer The address of loan manager
    /// @param termAuctionOfferLocker The address of auction offer locker paired through reopening
    /// @param termAuction The address of auction  paired through reopening
    event ReopeningOfferLockerPaired(
        bytes32 termRepoId,
        address termRepoServicer,
        address termAuctionOfferLocker,
        address termAuction
    );

    /// @notice Event emitted when a loan offer is locked.
    /// @param termRepoId A Term Repo id
    /// @param offeror The address who submitted offer
    /// @param amount The amount of purchase token locked for offer
    event OfferLockedByServicer(
        bytes32 termRepoId,
        address offeror,
        uint256 amount
    );

    /// @notice Event emitted when a loan offer is unlocked.
    /// @param termRepoId A Term Repo id
    /// @param offeror The address who submitted offer
    /// @param amount The amount of purchase token unlocked for offer
    event OfferUnlockedByServicer(
        bytes32 termRepoId,
        address offeror,
        uint256 amount
    );

    /// @notice Event emitted when a loan offer is fulfilled.
    /// @param offerId A unique offer id
    /// @param offeror The address whose offer is fulfilled
    /// @param purchasePrice The purchasePrice of loan offer fulfilled
    /// @param repurchasePrice The repurchasePrice of loan offer fulfilled
    /// @param repoTokensMinted The amount of Term Repo Tokens minted to offeror
    event OfferFulfilled(
        bytes32 offerId,
        address offeror,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        uint256 repoTokensMinted
    );

    /// @notice Event emitted when a term repo token is redeemed.
    /// @param termRepoId A Term Repo id
    /// @param redeemer The address who is redeeming term repo tokens
    /// @param redemptionAmount The amount of loan offer redeemed by term repo tokens
    /// @param redemptionHaircut The haircut applied to redemptions (if any) due to unrecoverable repo exposure
    event TermRepoTokensRedeemed(
        bytes32 termRepoId,
        address redeemer,
        uint256 redemptionAmount,
        uint256 redemptionHaircut
    );

    /// @notice Event emitted when a loan is processed to a borrower
    /// @param termRepoId A Term Repo id
    /// @param bidder The address who is receiving the loan
    /// @param purchasePrice The purchasePrice transferred to borrower
    /// @param repurchasePrice The repurchasePrice owed by borrower at maturity
    /// @param servicingFees The protocol fees paid for loan
    event BidFulfilled(
        bytes32 termRepoId,
        address bidder,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        uint256 servicingFees
    );

    /// @notice Event emitted when a rollover from a previous loan opens a position in this new term
    /// @param termRepoId A Term Repo id
    /// @param borrower The borrower who has loan position opened in new term
    /// @param purchasePrice The purchasePrice transferred to previous term
    /// @param repurchasePrice The repurchasePrice owed by borrower at maturity
    /// @param servicingFees The protocol fees paid for loan
    event ExposureOpenedOnRolloverNew(
        bytes32 termRepoId,
        address borrower,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        uint256 servicingFees
    );

    /// @notice Event emitted when a rollover from a previous loan opens a position in this new term
    /// @param termRepoId A Term Repo id
    /// @param borrower The borrower who has loan position opened in new term
    /// @param amountRolled The amount of borrower loan collapsed by rollover opening
    event ExposureClosedOnRolloverExisting(
        bytes32 termRepoId,
        address borrower,
        uint256 amountRolled
    );

    /// @notice Event emitted when term repo tokens are minted for a loan
    /// @param termRepoId A Term Repo id
    /// @param minter The address who is opening the loan
    /// @param netTokensReceived The amount of Term Repo Tokens received by minter net of servicing fees
    /// @param servicingFeeTokens The number of Term Repo Tokens retained by protocol in servicing fees
    /// @param repurchasePrice The repurchase exposure opened by minter against Term Repo Token mint
    event TermRepoTokenMint(
        bytes32 termRepoId,
        address minter,
        uint256 netTokensReceived,
        uint256 servicingFeeTokens,
        uint256 repurchasePrice
    );

    /// @notice Event emitted when a loan is collapsed by burning term repo tokens
    /// @param termRepoId A Term Repo id
    /// @param borrower The address who is repaying the loan
    /// @param amountToClose The amount repaid by borrower
    event BurnCollapseExposure(
        bytes32 termRepoId,
        address borrower,
        uint256 amountToClose
    );

    /// @notice Event emitted when a loan is repaid by borrower
    /// @param termRepoId A Term Repo id
    /// @param borrower The address who is repaying the loan
    /// @param repurchaseAmount The amount repaid by borrower
    event RepurchasePaymentSubmitted(
        bytes32 termRepoId,
        address borrower,
        uint256 repurchaseAmount
    );
}