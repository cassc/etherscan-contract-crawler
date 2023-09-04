//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./ITermRepoServicer.sol";
import "../lib/TermAuctionBid.sol";
import "../lib/TermAuctionBidSubmission.sol";
import "../lib/TermAuctionRevealedBid.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITermAuctionBidLocker {
    function termRepoId() external view returns (bytes32);

    function termAuctionId() external view returns (bytes32);

    function auctionEndTime() external view returns (uint256);

    function dayCountFractionMantissa() external view returns (uint256);

    function purchaseToken() external view returns (address);

    function collateralTokens(
        IERC20Upgradeable token
    ) external view returns (bool);

    function termRepoServicer() external view returns (ITermRepoServicer);

    // ========================================================================
    // = Interface/API ========================================================
    // ========================================================================

    /// @param bid A struct containing details of the bid
    /// @return A bool representing whether the bid was locked or not
    function lockRolloverBid(
        TermAuctionBid calldata bid
    ) external returns (bool);

    /// @param bidSubmissions An array of bid submissions
    /// @return A bytes32 array of unique on chain bid ids.
    function lockBids(
        TermAuctionBidSubmission[] calldata bidSubmissions
    ) external returns (bytes32[] memory);

    /// @param bidSubmissions An array of Term Auction bid submissions to borrow an amount of money at rate up to but not exceeding the bid rate
    /// @param referralAddress A user address that referred the submitter of this bid
    /// @return A bytes32 array of unique on chain bid ids.
    function lockBidsWithReferral(
        TermAuctionBidSubmission[] calldata bidSubmissions,
        address referralAddress
    ) external returns (bytes32[] memory);

    /// @param id A bid Id
    /// @return A struct containing details of the locked bid
    function lockedBid(
        bytes32 id
    ) external view returns (TermAuctionBid memory);

    /// @param ids An array of bid ids of the bids to reveal
    /// @param prices An array of the bid prices to reveal
    /// @param nonces An array of nonce values to generate bid price hashes
    function revealBids(
        bytes32[] calldata ids,
        uint256[] calldata prices,
        uint256[] calldata nonces
    ) external;

    /// @notice unlockBids unlocks multiple bids and returns funds to the borrower
    /// @param ids An array of ids to unlock
    function unlockBids(bytes32[] calldata ids) external;

    // ========================================================================
    // = Internal Interface/API ===============================================
    // ========================================================================

    /// @param revealedBids An array of the revealed offer ids
    /// @param expiredRolloverBids An array of the expired rollover bid ids
    /// @param unrevealedBids An array of the unrevealed offer ids
    /// @return An array of TermAuctionRevealedBid structs containing details of the revealed bids
    /// @return An array of TermAuctionBid structs containing details of the unrevealed bids
    function getAllBids(
        bytes32[] calldata revealedBids,
        bytes32[] calldata expiredRolloverBids,
        bytes32[] calldata unrevealedBids
    )
        external
        returns (TermAuctionRevealedBid[] memory, TermAuctionBid[] memory);

    /// @param id A bytes32 bid id
    /// @param bidder The address of the bidder
    /// @param bidCollateralTokens The addresses of the token used as collateral
    /// @param amounts The amounts of collateral tokens to unlock
    function auctionUnlockBid(
        bytes32 id,
        address bidder,
        address[] calldata bidCollateralTokens,
        uint256[] calldata amounts
    ) external;
}