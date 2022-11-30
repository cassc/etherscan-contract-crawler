//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IContangoView.sol";

/// @title Interface to allow for position management
interface IContango is IContangoView {
    /// @notice Creates a new position in the system by performing a trade of `quantity` at `limitCost` with `collateral`
    /// @param symbol Symbol of the instrument to be traded
    /// @param trader Which address will own the position
    /// @param quantity Desired position size. Always expressed in base currency, can't be zero
    /// @param limitCost The worst price the user is willing to accept (slippage). Always expressed in quote currency
    /// @param collateral Amount the user will post to secure the leveraged trade. Always expressed in quote currency
    /// @param payer Which address will pay for the trade
    /// @param lendingLiquidity Lend tokens 1:1 if there's low liquidity
    /// @return positionId Id of the newly created position
    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity
    ) external payable returns (PositionId positionId);

    /// @notice Modifies an existing position, changing its size & collateral (optional)
    /// @param positionId the id of an exiting position, the caller of this method must be its owner
    /// @param quantity Quantity to be increased (> 0) or decreased (< 0). Always expressed in base currency, can't be zero
    /// @param limitCost The worst price the user is willing to accept (slippage). Always expressed in quote currency
    /// @param collateral < 0 ? How much equity should be sent to `payerOrReceiver` : How much collateral will be taken from `payerOrReceiver` and added to the position
    /// @param payerOrReceiver Which address will receive the funds if `collateral` > 0, or which address will pay for the added funds if `collateral` > 0
    /// @param lendingLiquidity Deals with low liquidity, when decreasing, pay debt 1:1, when increasing lend tokens 1:1
    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable;

    /// @notice Modifies an existing position, adding or removing collateral
    /// @param positionId the id of an exiting position, the caller of this method must be its owner
    /// @param collateral Amount the user will add/remove. Positive to add, Negative to remove
    /// @param slippageTolerance the min/max amount the trader is willing to receive/pay
    /// @param payerOrReceiver Which address will pay/receive the collateral
    /// @param lendingLiquidity Deals with low liquidity paying debt 1:1
    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external payable;

    /// @notice Delivers an expired position by receiving the remaining payment for the leveraged position and physically delivering it
    /// @param positionId the id of an expired position, the caller of this method must be its owner
    /// @param payer Which address will pay for the remaining cost
    /// @param to Which address will receive the physical delivery
    function deliver(PositionId positionId, address payer, address to) external payable;
}