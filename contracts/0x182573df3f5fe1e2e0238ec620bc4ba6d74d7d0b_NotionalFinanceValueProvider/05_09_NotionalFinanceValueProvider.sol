// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Convert} from "../utils/Convert.sol";
import {Oracle} from "../../../oracle/Oracle.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import {INotionalView} from "./INotionalView.sol";
import {MarketParameters} from "./INotionalView.sol";

contract NotionalFinanceValueProvider is Oracle, Convert {
    /// @notice Emitted when trying to add pull a value for an expired pool
    error NotionalFinanceValueProvider__getValue_maturityLessThanBlocktime(
        uint256 maturity
    );

    /// @notice Emitted when an invalid currencyId is used to deploy the contract
    error NotionalFinanceValueProvider__constructor_invalidCurrencyId(
        uint256 currencyId
    );

    /// @notice Emitted when the parameters do not map to an active / initialized Notional Market
    error NotionalFinanceValueProvider__getValue_invalidMarketParameters(
        uint256 currencyId,
        uint256 maturityDate,
        uint256 settlementDate
    );

    // Seconds in a 360 days year as used by Notional in 18 digits precision
    int256 internal constant SECONDS_PER_YEAR = 31104000 * 1e18;

    // Quarter computed as it's defined in the Notional protocol
    // 3 months , 5 weeks per month, 6 days per week computed in seconds
    // Reference: https://github.com/notional-finance/contracts-v2/blob/master/contracts/global/Constants.sol#L56
    uint256 internal constant QUARTER = 3 * 5 * 6 * 86400;

    address public immutable notional;
    uint256 public immutable currencyId;
    uint256 public immutable maturityDate;
    uint256 public immutable oracleRateDecimals;

    /// @notice Constructs the Value provider contracts with the needed Notional contract data in order to
    /// calculate the per-second rate.
    /// @param timeUpdateWindow_ Minimum time between updates of the value
    /// @param notional_ The address of the deployed notional contract
    /// @param currencyId_ Currency ID(eth = 1, dai = 2, usdc = 3, wbtc = 4)
    /// @param oracleRateDecimals_ Precision of the Notional oracle rate
    /// @param maturityDate_ Maturity date.
    /// @dev reverts if the CurrencyId is bigger than uint16 max value
    constructor(
        // Oracle parameters
        uint256 timeUpdateWindow_,
        // Notional specific parameters
        address notional_,
        uint256 currencyId_,
        uint256 oracleRateDecimals_,
        uint256 maturityDate_
    ) Oracle(timeUpdateWindow_) {
        if (currencyId_ > type(uint16).max) {
            revert NotionalFinanceValueProvider__constructor_invalidCurrencyId(
                currencyId_
            );
        }

        oracleRateDecimals = oracleRateDecimals_;
        notional = notional_;
        currencyId = currencyId_;
        maturityDate = maturityDate_;
    }

    /// @notice Calculates the annual rate used by the FIAT DAO contracts
    /// the rate is precomputed by the notional contract and scaled to 1e18 precision
    /// @dev For more details regarding the computed rate in the Notional contracts:
    /// https://github.com/notional-finance/contracts-v2/blob/b8e3792e39486b2719c6153acc270199377cc6b9/contracts/internal/markets/Market.sol#L495
    /// @return result The result as an signed 59.18-decimal fixed-point number
    function getValue() external view override(Oracle) returns (int256) {
        // No values for matured pools
        if (block.timestamp >= maturityDate) {
            revert NotionalFinanceValueProvider__getValue_maturityLessThanBlocktime(
                maturityDate
            );
        }

        // Retrieve the oracle rate from Notional
        uint256 oracleRate = getOracleRate();

        // Convert rate per annum to 18 digits precision.
        uint256 ratePerAnnum = uconvert(oracleRate, oracleRateDecimals, 18);

        // Convert per annum to per second rate
        int256 ratePerSecondD59x18 = PRBMathSD59x18.div(
            int256(ratePerAnnum),
            SECONDS_PER_YEAR
        );

        // Convert continuous compounding to discrete compounding rate
        int256 discreteRateD59x18 = PRBMathSD59x18.exp(ratePerSecondD59x18) -
            PRBMathSD59x18.SCALE;

        // The result is a 59.18 fixed-point number.
        return discreteRateD59x18;
    }

    /// @notice Retrieve the oracle rate from the NotionalFinance Market
    function getOracleRate() internal view returns (uint256) {
        uint256 settlementDate = getSettlementDate();
        // Attempt to retrieve the oracle rate directly by using the maturity and settlement date
        MarketParameters memory marketParams = INotionalView(notional)
            .getMarket(uint16(currencyId), maturityDate, settlementDate);

        // If we find an active market we can return the oracle rate otherwise we revert
        if (marketParams.oracleRate <= 0) {
            revert NotionalFinanceValueProvider__getValue_invalidMarketParameters(
                currencyId,
                maturityDate,
                settlementDate
            );
        }

        return marketParams.oracleRate;
    }

    /// @notice Computes the settlement date as is done in the NotionalFinance contracts
    /// Reference 1:
    /// https://github.com/notional-finance/contracts-v2/blob/d89be9474e181b322480830501728ea625e853d0/contracts/internal/markets/DateTime.sol#L14
    /// Reference 2:
    /// https://github.com/notional-finance/contracts-v2/blob/d89be9474e181b322480830501728ea625e853d0/contracts/internal/markets/Market.sol#L536
    function getSettlementDate() public view returns (uint256) {
        return block.timestamp - (block.timestamp % QUARTER) + QUARTER;
    }
}