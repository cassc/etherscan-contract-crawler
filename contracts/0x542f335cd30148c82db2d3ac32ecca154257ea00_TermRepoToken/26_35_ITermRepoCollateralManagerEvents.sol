//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoCollateralManagerEvents is an interface that defines all events emitted by Term Repo Collateral Manager.
interface ITermRepoCollateralManagerEvents {
    /// @notice Event emitted when a Term Repo Collateral Manager is initialized.
    /// @param termRepoId                  term identifier
    /// @param collateralTokens        addresses of accepted collateral tokens
    /// @param initialCollateralRatios list of initial collateral ratios for each collateral token in the same order as collateral tokens list
    /// @param maintenanceCollateralRatios       list of maintenance ratios for each collateral token in the same order as collateral tokens list
    /// @param liquidatedDamagesSchedule    liquidation discounts for collateral tokens
    event TermRepoCollateralManagerInitialized(
        bytes32 termRepoId,
        address termRepoCollateralManager,
        address[] collateralTokens,
        uint256[] initialCollateralRatios,
        uint256[] maintenanceCollateralRatios,
        uint256[] liquidatedDamagesSchedule
    );

    /// @notice Event emitted when existing Term Repo Locker is reopened to another auction group
    /// @param termRepoId                     term identifier
    /// @param termRepoCollateralManager          address of collateral manager
    /// @param termAuctionBidLocker       address of auction bid locker paired through reopening
    event PairReopeningBidLocker(
        bytes32 termRepoId,
        address termRepoCollateralManager,
        address termAuctionBidLocker
    );

    /// @notice Event emitted when collateral is locked.
    /// @param termRepoId             term identifier
    /// @param borrower           address of borrower who locked collateral
    /// @param collateralToken    address of collateral token
    /// @param amount             amount of collateral token locked
    event CollateralLocked(
        bytes32 termRepoId,
        address borrower,
        address collateralToken,
        uint256 amount
    );

    /// @notice Event emitted when collateral is locked.
    /// @param termRepoId             term identifier
    /// @param borrower           address of borrower who locked collateral
    /// @param collateralToken    address of collateral token
    /// @param amount             amount of collateral token unlocked
    event CollateralUnlocked(
        bytes32 termRepoId,
        address borrower,
        address collateralToken,
        uint256 amount
    );

    /// @notice Event emitted when a liquidation occurs
    /// @param termRepoId                term identifier
    /// @param borrower              address of borrower being liquidated
    /// @param liquidator            address of liquidator
    /// @param closureAmount       amount of loan repaid by liquidator
    /// @param collateralToken       address of collateral token liquidated
    /// @param amountLiquidated      amount of collateral liquidated
    /// @param protocolSeizureAmount amount of collateral liquidated and seized by protocol as fee
    /// @param defaultLiquidation    boolean indicating if liquidation is a default or not
    event Liquidation(
        bytes32 termRepoId,
        address borrower,
        address liquidator,
        uint256 closureAmount,
        address collateralToken,
        uint256 amountLiquidated,
        uint256 protocolSeizureAmount,
        bool defaultLiquidation
    );

    /// @notice Event emitted when a Liquidations are paused for a term
    /// @param termRepoId                     term identifier
    event LiquidationsPaused(bytes32 termRepoId);

    /// @notice Event emitted when a Liquidations are unpaused for a term
    /// @param termRepoId                     term identifier
    event LiquidationsUnpaused(bytes32 termRepoId);
}