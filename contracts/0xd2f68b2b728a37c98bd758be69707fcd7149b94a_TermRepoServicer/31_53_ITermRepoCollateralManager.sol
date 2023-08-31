//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "../lib/ExponentialNoError.sol";
import "./ITermRepoLocker.sol";

/// @notice ITermManager represents a contract that manages all
interface ITermRepoCollateralManager {
    // ========================================================================
    // = State Variables  =====================================================
    // ========================================================================

    function termRepoLocker() external view returns (ITermRepoLocker);

    function maintenanceCollateralRatios(
        address
    ) external view returns (uint256);

    function initialCollateralRatios(address) external view returns (uint256);

    function numOfAcceptedCollateralTokens() external view returns (uint8);

    function collateralTokens(uint256 index) external view returns (address);

    function encumberedCollateralRemaining() external view returns (bool);

    // ========================================================================
    // = Auction Functions  ===================================================
    // ========================================================================

    /// @param bidder The bidder's address
    /// @param collateralToken The address of the token to be used as collateral
    /// @param amount The amount of the token to lock
    function auctionLockCollateral(
        address bidder,
        address collateralToken,
        uint256 amount
    ) external;

    /// @param bidder The bidder's address
    /// @param collateralToken The address of the token used as collateral
    /// @param amount The amount of collateral tokens to unlock
    function auctionUnlockCollateral(
        address bidder,
        address collateralToken,
        uint256 amount
    ) external;

    // ========================================================================
    // = Rollover Functions  ==================================================
    // ========================================================================

    /// @param borrower The borrower's address
    /// @param rolloverProportion The proportion of the collateral to be unlocked, equal to the proportion of the collateral repaid
    /// @param rolloverTermRepoLocker The address of the new TermRepoLocker contract to roll into
    /// @return An array representing a list of accepted collateral token addresses
    /// @return An array containing the amount of collateral tokens to pairoff and transfer to new TermRepoLocker to roll into
    function transferRolloverCollateral(
        address borrower,
        uint256 rolloverProportion,
        address rolloverTermRepoLocker
    ) external returns (address[] memory, uint256[] memory);

    /// @param borrower The address of the borrower
    /// @param collateralToken The address of a collateral token
    /// @param amount The amount of collateral tokens to lock
    function acceptRolloverCollateral(
        address borrower,
        address collateralToken,
        uint256 amount
    ) external;

    /// @param rolloverAuction The address of the rollover auction
    function approveRolloverAuction(address rolloverAuction) external;

    // ========================================================================
    // = APIs  ================================================================
    // ========================================================================

    /// @param collateralToken The address of the collateral token to lock
    /// @param amount The amount of collateral token to lock
    function externalLockCollateral(
        address collateralToken,
        uint256 amount
    ) external;

    /// @param collateralToken The address of the collateral token to unlock
    /// @param amount The amount of collateral token to unlock
    function externalUnlockCollateral(
        address collateralToken,
        uint256 amount
    ) external;

    /// @param borrower The address of the borrower
    /// @return The market value of borrower's locked collateral denominated in USD
    function getCollateralMarketValue(
        address borrower
    ) external view returns (uint256);

    // ========================================================================
    // = Margin Maintenance Functions  ========================================
    // ========================================================================

    /// @param borrower The address of the borrower
    function unlockCollateralOnRepurchase(address borrower) external;

    /// @param borrower The address of the borrower
    /// @param collateralTokenAddresses Collateral token addresses
    /// @param collateralTokenAmounts Collateral token amounts
    function journalBidCollateralToCollateralManager(
        address borrower,
        address[] calldata collateralTokenAddresses,
        uint256[] calldata collateralTokenAmounts
    ) external;

    /// @param borrower The address of the borrower
    /// @param collateralToken Collateral token addresse
    /// @param amount Collateral token amount
    function mintOpenExposureLockCollateral(
        address borrower,
        address collateralToken,
        uint256 amount
    ) external;

    /// @param collateralToken The collateral token address of tokens locked
    /// @param amountToLock The amount of collateral tokens to lock
    function calculateMintableExposure(
        address collateralToken,
        uint256 amountToLock
    ) external view returns (ExponentialNoError.Exp memory);

    /// @param borrower The address of the borrower
    /// @param collateralToken The collateral token address to query
    /// @return uint256 The amount of collateralToken locked on behalf of borrower
    function getCollateralBalance(
        address borrower,
        address collateralToken
    ) external view returns (uint256);

    /// @param borrower The address of the borrower
    /// @return An array of collateral token addresses
    /// @return An array collateral token balances locked on behalf of borrower
    function getCollateralBalances(
        address borrower
    ) external view returns (address[] memory, uint256[] memory);

    /// @param borrower The address of the borrower
    /// @param closureAmounts An array specifying the amounts of Term Repo exposure the liquidator proposes to cover in liquidation; an amount is required to be specified for each collateral token
    function batchDefault(
        address borrower,
        uint256[] calldata closureAmounts
    ) external;

    /// @param borrower The address of the borrower
    /// @param closureAmounts An array specifying the amounts of Term Repo exposure the liquidator proposes to cover in liquidation; an amount is required to be specified for each collateral token
    function batchLiquidation(
        address borrower,
        uint256[] calldata closureAmounts
    ) external;

    /// @param borrower The address of the borrower
    /// @param closureRepoTokenAmounts An array specifying the amounts of Term Repo Tokens the liquidator proposes to cover borrower repo exposure in liquidation; an amount is required to be specified for each collateral token
    function batchLiquidationWithRepoToken(
        address borrower,
        uint256[] calldata closureRepoTokenAmounts
    ) external;
}