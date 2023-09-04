//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./ITermRepoCollateralManager.sol";
import "./ITermRepoRolloverManager.sol";
import "./ITermRepoLocker.sol";

/// @notice ITermRepoServicer represents a contract that manages all
interface ITermRepoServicer {
    // ========================================================================
    // = State Variables  =====================================================
    // ========================================================================

    function endOfRepurchaseWindow() external view returns (uint256);

    function maturityTimestamp() external view returns (uint256);

    function redemptionTimestamp() external view returns (uint256);

    function purchaseToken() external view returns (address);

    function servicingFee() external view returns (uint256);

    function termRepoCollateralManager()
        external
        view
        returns (ITermRepoCollateralManager);

    function termRepoRolloverManager()
        external
        view
        returns (ITermRepoRolloverManager);

    function termRepoLocker() external view returns (ITermRepoLocker);

    // ========================================================================
    // = Auction Functions  ===================================================
    // ========================================================================

    /// @param offeror The address of the offeror
    /// @param amount The amount of purchase tokens to lock
    function lockOfferAmount(address offeror, uint256 amount) external;

    /// @param offeror The address of the offeror
    /// @param amount The amount of purchase tokens to unlocked
    function unlockOfferAmount(address offeror, uint256 amount) external;

    /// @param offeror The address of the offeror
    /// @param purchasePrice The offer amount to fulfill
    /// @param repurchasePrice The repurchase price due to offeror at maturity
    /// @param offerId A unique offer id
    function fulfillOffer(
        address offeror,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        bytes32 offerId
    ) external;

    /// @param redeemer The address of redeemer
    /// @param amountToRedeem The amount of TermRepoTokens to redeem
    function redeemTermRepoTokens(
        address redeemer,
        uint256 amountToRedeem
    ) external;

    /// @dev This method allows MINTER_ROLE to open repurchase price exposure against a TermRepoToken mint of corresponding value outside of a Term Auction to create new supply
    /// @param amount The amount of Term Repo Tokens to mint
    /// @param collateralAmounts An array containing an amount of collateral token for each token in collateral basket
    function mintOpenExposure(
        uint256 amount,
        uint256[] calldata collateralAmounts
    ) external;

    /// @param bidder The address of the bidder
    /// @param purchasePrice The bid amount to fulfill
    /// @param repurchasePrice The repurchase price due at maturity
    /// @param collateralTokens Collateral token addresses
    /// @param collateralAmounts Collateral token amounts
    /// @param dayCountFractionMantissa Actual/360 day count fraction parameter from Term Auction Group
    function fulfillBid(
        address bidder,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        address[] calldata collateralTokens,
        uint256[] calldata collateralAmounts,
        uint256 dayCountFractionMantissa
    ) external;

    // ========================================================================
    // = Rollover Functions  ==================================================
    // ========================================================================

    /// @param termAuction The address of a TermAuction contract to receive autioneer role
    function approveRolloverAuction(address termAuction) external;

    /// @param borrower The address of the borrower rolling into new Term Repo
    /// @param purchasePrice The purchase price received from new TermRepo
    /// @param repurchasePrice The new repurchase price due at maturity of new TermRepo
    /// @param previousTermRepoLocker The address of the old TermRepoLocker contract
    /// @param dayCountFractionMantissa Actual/360 day count fraction parameter from Term Auction Group
    /// @return The net purchase price received in after deducing protocol servicing fees
    function openExposureOnRolloverNew(
        address borrower,
        uint256 purchasePrice,
        uint256 repurchasePrice,
        address previousTermRepoLocker,
        uint256 dayCountFractionMantissa
    ) external returns (uint256);

    /// @param borrower The address of the borrower
    /// @param rolloverSettlementAmount The amount of net proceeds received from new TermRepo to pay down existing repurchase obligation due to old Term Repo
    /// @return A uint256 representing the proportion of total repurchase due to old Term Repo from borrower settled by proceeds from new TermRepo
    function closeExposureOnRolloverExisting(
        address borrower,
        uint256 rolloverSettlementAmount
    ) external returns (uint256);

    // ========================================================================
    // = APIs  ================================================================
    // ========================================================================

    /// @notice The max repurchase amount is the repurchase balance less any amounts earmarked for rollover
    /// @param amount The amount of purchase token to submit for repurchase
    function submitRepurchasePayment(uint256 amount) external;

    /// @param amountToBurn The amount of TermRepoTokens to burn
    function burnCollapseExposure(uint256 amountToBurn) external;

    /// @param borrower The address of the borrower to query
    /// @return The total repurchase price due at maturity for a given borrower
    function getBorrowerRepurchaseObligation(
        address borrower
    ) external view returns (uint256);

    /// @param borrower The address of the borrower
    /// @param liquidator The address of the liquidator
    /// @param amountToCover The amount of repurchase exposure to cover in liquidation
    function liquidatorCoverExposure(
        address borrower,
        address liquidator,
        uint256 amountToCover
    ) external;

    /// @param borrower The address of the borrower
    /// @param liquidator The address of the liquidator
    /// @param amountOfRepoToken The amount of term tokens used to cover in liquidation
    /// @return A uint256 representing purchase value of repo tokens burned
    function liquidatorCoverExposureWithRepoToken(
        address borrower,
        address liquidator,
        uint256 amountOfRepoToken
    ) external returns (uint256);

    /// @return A boolean that represents whether the term repo locker is balanced
    function isTermRepoBalanced() external view returns (bool);
}