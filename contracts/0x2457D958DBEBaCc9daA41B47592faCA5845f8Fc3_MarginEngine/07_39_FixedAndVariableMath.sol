// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "./Time.sol";

/// @title A utility library for mathematics of fixed and variable token amounts.
library FixedAndVariableMath {
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;

    /// @notice Number of wei-seconds in a year
    /// @dev Ignoring leap years since we're only using it to calculate the eventual APY rate

    uint256 public constant SECONDS_IN_YEAR_IN_WAD = 31536000e18;
    uint256 public constant ONE_HUNDRED_IN_WAD = 100e18;

    /// @notice Caclulate the remaining cashflow to settle a position
    /// @param fixedTokenBalance The current balance of the fixed side of the position
    /// @param variableTokenBalance The current balance of the variable side of the position
    /// @param termStartTimestampWad When did the position begin, in seconds
    /// @param termEndTimestampWad When does the position reach maturity, in seconds
    /// @param variableFactorToMaturityWad What factor expresses the current remaining variable rate, up to position maturity? (in wad)
    /// @return cashflow The remaining cashflow of the position
    function calculateSettlementCashflow(
        int256 fixedTokenBalance,
        int256 variableTokenBalance,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad,
        uint256 variableFactorToMaturityWad
    ) internal view returns (int256 cashflow) {
        /// @dev convert fixed and variable token balances to their respective fixed token representations

        int256 fixedTokenBalanceWad = fixedTokenBalance.fromInt();
        int256 variableTokenBalanceWad = variableTokenBalance.fromInt();
        int256 fixedCashflowWad = fixedTokenBalanceWad.mul(
            int256(
                fixedFactor(true, termStartTimestampWad, termEndTimestampWad)
            )
        );

        int256 variableCashflowWad = variableTokenBalanceWad.mul(
            int256(variableFactorToMaturityWad)
        );

        int256 cashflowWad = fixedCashflowWad + variableCashflowWad;

        /// @dev convert back to non-fixed point representation
        cashflow = cashflowWad.toInt();
    }

    /// @notice Divide a given time in seconds by the number of seconds in a year
    /// @param timeInSecondsAsWad A time in seconds in Wad (i.e. scaled up by 10^18)
    /// @return timeInYearsWad An annualised factor of timeInSeconds, also in Wad
    function accrualFact(uint256 timeInSecondsAsWad)
        internal
        pure
        returns (uint256 timeInYearsWad)
    {
        timeInYearsWad = timeInSecondsAsWad.div(SECONDS_IN_YEAR_IN_WAD);
    }

    /// @notice Calculate the fixed factor for a position - that is, the percentage earned over
    /// the specified period of time, assuming 1% per year
    /// @param atMaturity Whether to calculate the factor at maturity (true), or now (false)
    /// @param termStartTimestampWad When does the period of time begin, in wei-seconds
    /// @param termEndTimestampWad When does the period of time end, in wei-seconds
    /// @return fixedFactorValueWad The fixed factor for the position (in Wad)
    function fixedFactor(
        bool atMaturity,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad
    ) internal view returns (uint256 fixedFactorValueWad) {
        require(termEndTimestampWad > termStartTimestampWad, "E<=S");

        uint256 currentTimestampWad = Time.blockTimestampScaled();

        require(currentTimestampWad >= termStartTimestampWad, "B.T<S");

        uint256 timeInSecondsWad;

        if (atMaturity || (currentTimestampWad >= termEndTimestampWad)) {
            timeInSecondsWad = termEndTimestampWad - termStartTimestampWad;
        } else {
            timeInSecondsWad = currentTimestampWad - termStartTimestampWad;
        }

        fixedFactorValueWad = accrualFact(timeInSecondsWad).div(
            ONE_HUNDRED_IN_WAD
        );
    }

    /// @notice Calculate the fixed token balance for a position over a timespan
    /// @param amountFixedWad  A fixed amount
    /// @param excessBalanceWad Cashflows accrued to the fixed and variable token amounts since the inception of the IRS AMM
    /// @param termStartTimestampWad When does the period of time begin, in wei-seconds
    /// @param termEndTimestampWad When does the period of time end, in wei-seconds
    /// @return fixedTokenBalanceWad The fixed token balance for that time period
    function calculateFixedTokenBalance(
        int256 amountFixedWad,
        int256 excessBalanceWad,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad
    ) internal view returns (int256 fixedTokenBalanceWad) {
        require(termEndTimestampWad > termStartTimestampWad, "E<=S");

        return
            amountFixedWad -
            excessBalanceWad.div(
                int256(
                    fixedFactor(
                        true,
                        termStartTimestampWad,
                        termEndTimestampWad
                    )
                )
            );
    }

    /// @notice Calculate the excess balance of both sides of a position in Wad
    /// @param amountFixedWad A fixed balance
    /// @param amountVariableWad A variable balance
    /// @param accruedVariableFactorWad An annualised factor in wei-years
    /// @param termStartTimestampWad When does the period of time begin, in wei-seconds
    /// @param termEndTimestampWad When does the period of time end, in wei-seconds
    /// @return excessBalanceWad The excess balance in wad
    function getExcessBalance(
        int256 amountFixedWad,
        int256 amountVariableWad,
        uint256 accruedVariableFactorWad,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad
    ) internal view returns (int256) {
        /// @dev cashflows accrued since the inception of the IRS AMM

        return
            amountFixedWad.mul(
                int256(
                    fixedFactor(
                        false,
                        termStartTimestampWad,
                        termEndTimestampWad
                    )
                )
            ) + amountVariableWad.mul(int256(accruedVariableFactorWad));
    }

    /// @notice Calculate the fixed token balance given both fixed and variable balances
    /// @param amountFixed A fixed balance
    /// @param amountVariable A variable balance
    /// @param accruedVariableFactorWad An annualised factor in wei-years
    /// @param termStartTimestampWad When does the period of time begin, in wei-seconds
    /// @param termEndTimestampWad When does the period of time end, in wei-seconds
    /// @return fixedTokenBalance The fixed token balance for that time period
    function getFixedTokenBalance(
        int256 amountFixed,
        int256 amountVariable,
        uint256 accruedVariableFactorWad,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad
    ) internal view returns (int256 fixedTokenBalance) {
        require(termEndTimestampWad > termStartTimestampWad, "E<=S");

        if (amountFixed == 0 && amountVariable == 0) return 0;

        int256 amountFixedWad = amountFixed.fromInt();
        int256 amountVariableWad = amountVariable.fromInt();

        int256 excessBalanceWad = getExcessBalance(
            amountFixedWad,
            amountVariableWad,
            accruedVariableFactorWad,
            termStartTimestampWad,
            termEndTimestampWad
        );

        int256 fixedTokenBalanceWad = calculateFixedTokenBalance(
            amountFixedWad,
            excessBalanceWad,
            termStartTimestampWad,
            termEndTimestampWad
        );

        fixedTokenBalance = fixedTokenBalanceWad.toInt();
    }
}