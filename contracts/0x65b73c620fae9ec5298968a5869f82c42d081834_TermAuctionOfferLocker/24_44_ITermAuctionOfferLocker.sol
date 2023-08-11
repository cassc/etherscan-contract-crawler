//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "../lib/TermAuctionOffer.sol";
import "../lib/TermAuctionOfferSubmission.sol";
import "../lib/TermAuctionRevealedOffer.sol";

interface ITermAuctionOfferLocker {
    function auctionEndTime() external view returns (uint256);

    // ========================================================================
    // = Interface/API ========================================================
    // ========================================================================

    /// @param offerSubmissions An array of offer submissions
    /// @return A bytes32 array of unique on chain offer ids.
    function lockOffers(
        TermAuctionOfferSubmission[] calldata offerSubmissions
    ) external returns (bytes32[] memory);

    /// @param offerSubmissions An array of Term Auction offer submissions to lend an amount of money at rate no lower than the offer rate
    /// @param referralAddress A user address that referred the submitter of this offer
    /// @return A bytes32 array of unique on chain offer ids.
    function lockOffersWithReferral(
        TermAuctionOfferSubmission[] calldata offerSubmissions,
        address referralAddress
    ) external returns (bytes32[] memory);

    /// @param id An offer Id
    /// @return A struct containing the details of the locked offer
    function lockedOffer(
        bytes32 id
    ) external view returns (TermAuctionOffer memory);

    /// @param ids An array offer ids to reveal
    /// @param prices An array of the offer prices to reveal
    /// @param nonces An array of nonce values to generate bid price hashes
    function revealOffers(
        bytes32[] calldata ids,
        uint256[] calldata prices,
        uint256[] calldata nonces
    ) external;

    /// @notice unlockOffers unlocks multiple offers and returns funds to the offeror
    /// @param ids An array of offer ids
    function unlockOffers(bytes32[] calldata ids) external;

    // ========================================================================
    // = Internal Interface/API ===============================================
    // ========================================================================

    /// @param revealedOffers An array of the revealed offer ids
    /// @param unrevealedOffers An array of the unrevealed offer ids
    /// @return An array of TermAuctionRevealedOffer structs containing details of the revealed offers
    /// @return An array of TermAuctionOffer structs containing details of the unrevealed offers
    function getAllOffers(
        bytes32[] calldata revealedOffers,
        bytes32[] calldata unrevealedOffers
    )
        external
        returns (TermAuctionRevealedOffer[] memory, TermAuctionOffer[] memory);

    /// @param id An offer Id
    /// @param offeror The address of the offeror
    /// @param amount The amount to unlock
    function unlockOfferPartial(
        bytes32 id,
        address offeror,
        uint256 amount
    ) external;
}