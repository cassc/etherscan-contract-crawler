/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;

interface IPerpetual {
    /// @notice Return the paper amount and credit amount of a certain trader.
    /// @return paper is positive when the trader holds a long position and
    /// negative when the trader holds a short position.
    /// @return credit is not related to position direction or entry price,
    /// only used to calculate risk ratio and net value.
    function balanceOf(address trader)
        external
        view
        returns (int256 paper, int256 credit);

    /// @notice Match and settle orders.
    /// @dev tradeData will be forwarded to the Dealer contract and waiting
    /// for matching result. Then the Perpetual contract will execute the result.
    function trade(bytes calldata tradeData) external;

    /// @notice Liquidate a position with customized paper amount and price protection.
    /// @dev Because the liquidation is open to public, there is no guarantee that
    /// your request will be executed.
    /// It will not be executed or partially executed if:
    /// 1) someone else submitted a liquidation request before you, or
    /// 2) the trader deposited enough margin in time, or
    /// 3) the mark price moved beyond your price protection.
    /// Your liquidation will be limited to the position size. For example, if the
    /// position remains 10ETH and you're requesting a 15ETH liquidation. Only 10ETH
    /// will be executed. And the other 5ETH request will be cancelled.
    /// @param  liquidatedTrader is the trader you want to liquidate.
    /// @param  requestPaper is the size of position you want to take .
    /// requestPaper is positive when you want to liquidate a long position, negative when short.
    /// @param expectCredit is the amount of credit you want to pay (when liquidating a short position)
    /// or receive (when liquidating a long position)
    /// @return liqtorPaperChange is the final executed change of liquidator's paper amount
    /// @return liqtorCreditChange is the final executed change of liquidator's credit amount
    function liquidate(
        address liquidatedTrader,
        int256 requestPaper,
        int256 expectCredit
    ) external returns (int256 liqtorPaperChange, int256 liqtorCreditChange);

    /// @notice Get funding rate of this perpetual market.
    /// Funding rate is a 1e18 based decimal.
    function getFundingRate() external view returns (int256);

    /// @notice Update funding rate, owner only function.
    function updateFundingRate(int256 newFundingRate) external;
}