/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./JOJOStorage.sol";
import "../utils/Errors.sol";
import "../intf/IDealer.sol";
import "../lib/Liquidation.sol";
import "../lib/Trading.sol";

abstract contract JOJOView is JOJOStorage, IDealer {
    // ========== simple read state ==========

    /// @inheritdoc IDealer
    function getRiskParams(address perp)
        external
        view
        returns (Types.RiskParams memory params)
    {
        params = state.perpRiskParams[perp];
    }

    /// @inheritdoc IDealer
    function getAllRegisteredPerps() external view returns (address[] memory) {
        return state.registeredPerp;
    }

    /// @inheritdoc IDealer
    function getMarkPrice(address perp) external view returns (uint256) {
        return Liquidation.getMarkPrice(state, perp);
    }

    /// @inheritdoc IDealer
    function getPositions(address trader)
        external
        view
        returns (address[] memory)
    {
        return state.openPositions[trader];
    }

    /// @inheritdoc IDealer
    function getCreditOf(address trader)
        external
        view
        returns (
            int256 primaryCredit,
            uint256 secondaryCredit,
            uint256 pendingPrimaryWithdraw,
            uint256 pendingSecondaryWithdraw,
            uint256 executionTimestamp
        )
    {
        primaryCredit = state.primaryCredit[trader];
        secondaryCredit = state.secondaryCredit[trader];
        pendingPrimaryWithdraw = state.pendingPrimaryWithdraw[trader];
        pendingSecondaryWithdraw = state.pendingSecondaryWithdraw[trader];
        executionTimestamp = state.withdrawExecutionTimestamp[trader];
    }

    /// @inheritdoc IDealer
    function isOrderSenderValid(address orderSender)
        external
        view
        returns (bool)
    {
        return state.validOrderSender[orderSender];
    }

    /// @inheritdoc IDealer
    function isOperatorValid(address client, address operator)
        external
        view
        returns (bool)
    {
        return state.operatorRegistry[client][operator];
    }

    // ========== liquidation related ==========

    /// @inheritdoc IDealer
    function isSafe(address trader) external view returns (bool safe) {
        return Liquidation._isSafe(state, trader);
    }

    /// @inheritdoc IDealer
    function isAllSafe(address[] calldata traderList)
        external
        view
        returns (bool safe)
    {
        return Liquidation._isAllSafe(state, traderList);
    }

    /// @inheritdoc IDealer
    function getFundingRate(address perp) external view returns (int256) {
        return IPerpetual(perp).getFundingRate();
    }

    /// @inheritdoc IDealer
    function getTraderRisk(address trader)
        external
        view
        returns (
            int256 netValue,
            uint256 exposure,
            uint256 maintenanceMargin
        )
    {
        int256 positionNetValue;
        (positionNetValue, exposure, maintenanceMargin) = Liquidation
            .getTotalExposure(state, trader);
        netValue =
            positionNetValue +
            state.primaryCredit[trader] +
            int256(state.secondaryCredit[trader]);
    }

    /// @inheritdoc IDealer
    function getLiquidationPrice(address trader, address perp)
        external
        view
        returns (uint256 liquidationPrice)
    {
        return Liquidation.getLiquidationPrice(state, trader, perp);
    }

    /// @inheritdoc IDealer
    function getLiquidationCost(
        address perp,
        address liquidatedTrader,
        int256 requestPaperAmount
    )
        external
        view
        returns (int256 liqtorPaperChange, int256 liqtorCreditChange)
    {
        (liqtorPaperChange, liqtorCreditChange, ) = Liquidation
            .getLiquidateCreditAmount(
                state,
                perp,
                liquidatedTrader,
                requestPaperAmount
            );
    }

    // ========== order related ==========

    /// @inheritdoc IDealer
    function getOrderFilledAmount(bytes32 orderHash)
        external
        view
        returns (uint256 filledAmount)
    {
        filledAmount = state.orderFilledPaperAmount[orderHash];
    }
}