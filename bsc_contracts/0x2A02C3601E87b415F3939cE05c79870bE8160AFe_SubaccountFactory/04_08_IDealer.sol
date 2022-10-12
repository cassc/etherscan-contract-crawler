/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;

import "../lib/Types.sol";

interface IDealer {
    /// @notice Deposit fund to get credit for trading
    /// @param primaryAmount is the amount of primary asset you want to deposit.
    /// @param secondaryAmount is the amount of secondary asset you want to deposit.
    /// @param to is the account you want to deposit to.
    function deposit(
        uint256 primaryAmount,
        uint256 secondaryAmount,
        address to
    ) external;

    /// @notice Submit withdrawal request, which can be executed after
    /// the timelock. The main purpose of this function is to avoid the
    /// failure of counterparty caused by withdrawal.
    /// @param primaryAmount is the amount of primary asset you want to withdraw.
    /// @param secondaryAmount is the amount of secondary asset you want to withdraw.
    function requestWithdraw(uint256 primaryAmount, uint256 secondaryAmount)
        external;

    /// @notice Execute the withdrawal request.
    /// @param to is the address receiving assets.
    /// @param isInternal Only internal credit transfers will be made,
    /// and ERC20 transfers will not happen.
    function executeWithdraw(address to, bool isInternal) external;

    /// @notice Help perpetual contract parse tradeData and return
    /// the balance changes of each trader.
    /// @dev only perpetual contract can call this function
    /// @param orderSender is the one who submit tradeData.
    /// @param tradeData contains orders, signatures and match info.
    function approveTrade(address orderSender, bytes calldata tradeData)
        external
        returns (
            address[] memory traderList,
            int256[] memory paperChangeList,
            int256[] memory creditChangeList
        );

    /// @notice Check if the trader's margin is enough (>= maintenance margin).
    /// If so, the trader is "safe".
    /// The trader's positions under all markets will be liquidated if he is
    /// not safe.
    function isSafe(address trader) external view returns (bool);

    /// @notice Check if a list of traders are safe.
    /// @dev This function is more gas effective than isSafe, by caching
    /// mark prices.
    function isAllSafe(address[] calldata traderList)
        external
        view
        returns (bool);

    /// @notice Get funding rate of a perpetual market.
    /// Funding rate is a 1e18 based decimal.
    function getFundingRate(address perp) external view returns (int256);

    /// @notice Update multiple funding rate at once.
    /// Can only be called by funding rate keeper.
    function updateFundingRate(
        address[] calldata perpList,
        int256[] calldata rateList
    ) external;

    /// @notice Calculate the paper and credit change of liquidator and
    /// liquidated trader.
    /// @dev Only perpetual contract can call this function.
    /// liqtor is short for liquidator, liqed is short for liquidated trader.
    /// @param liquidator is the one who will take over positions.
    /// @param liquidatedTrader is the one who is being liquidated.
    /// @param requestPaperAmount is the size that the liquidator wants to take.
    /// Positive if the position is long, negative if the position is short.
    function requestLiquidation(
        address liquidator,
        address liquidatedTrader,
        int256 requestPaperAmount
    )
        external
        returns (
            int256 liqtorPaperChange,
            int256 liqtorCreditChange,
            int256 liqedPaperChange,
            int256 liqedCreditChange
        );

    /// @notice Transfer all bad debt to insurance account,
    /// including primary and secondary balances.
    function handleBadDebt(address liquidatedTrader) external;

    /// @notice Register the trader's position into dealer.
    /// @dev Only perpetual contract can call this function when
    /// someone's position is opened.
    function openPosition(address trader) external;

    /// @notice Accrual realized pnl and remove the trader's position from dealer.
    /// @dev Only perpetual contract can call this function when
    /// someone's position is closed.
    function realizePnl(address trader, int256 pnl) external;

    /// @notice Register operator.
    /// The operator can sign order on your behalf.
    function setOperator(address operator, bool isValid) external;

    /// @param perp the address of perpetual contract market
    function getRiskParams(address perp)
        external
        view
        returns (Types.RiskParams memory params);

    /// @notice Return all registered perpetual contract market.
    function getAllRegisteredPerps() external view returns (address[] memory);

    /// @notice Return mark price of a perpetual market.
    /// price is a 1e18 based decimal.
    function getMarkPrice(address perp) external view returns (uint256);

    /// @notice Get all open positions of the trader.
    function getPositions(address trader)
        external
        view
        returns (address[] memory);

    /// @notice Return the credit details of the trader.
    /// You cannot use credit as net value or net margin of a trader.
    /// The net value of positions would also be included.
    function getCreditOf(address trader)
        external
        view
        returns (
            int256 primaryCredit,
            uint256 secondaryCredit,
            uint256 pendingPrimaryWithdraw,
            uint256 pendingSecondaryWithdraw,
            uint256 executionTimestamp
        );

    /// @notice Get the risk profile data of a trader.
    /// @return netValue net value of trader including credit amount
    /// @return exposure open position value of the trader across all markets
    function getTraderRisk(address trader)
        external
        view
        returns (
            int256 netValue,
            uint256 exposure,
            uint256 maintenanceMargin
        );

    /// @notice Get liquidation price of a position
    /// @dev This function is for directional use. The margin of error is typically
    /// within 10 wei.
    /// @return liquidationPrice equals 0 if there is no liquidation price.
    function getLiquidationPrice(address trader, address perp)
        external
        view
        returns (uint256 liquidationPrice);

    /// @notice a view version of requestLiquidation, liquidators can use
    /// this function to check how much you have to pay in advance.
    function getLiquidationCost(
        address perp,
        address liquidatedTrader,
        int256 requestPaperAmount
    )
        external
        view
        returns (int256 liqtorPaperChange, int256 liqtorCreditChange);

    /// @notice Get filled paper amount of an order to avoid double matching.
    /// @return filledAmount includes paper amount
    function getOrderFilledAmount(bytes32 orderHash)
        external
        view
        returns (uint256 filledAmount);

    /// @notice check if order sender is valid
    function isOrderSenderValid(address orderSender)
        external
        view
        returns (bool);

    /// @notice check if operator is valid
    function isOperatorValid(address client, address operator)
        external
        view
        returns (bool);
}