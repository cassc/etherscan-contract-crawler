/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity ^0.8.13;

/**
 * @title Interest Rate Module.
 * @author Pragma Labs
 * @notice The Logic to calculate and store the interest rate of the Lending Pool.
 */
contract InterestRateModule {
    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // The current interest rate, 18 decimals precision.
    uint256 public interestRate;

    // A struct with the configuration of the interest rate curves,
    // which give the interest rate in function of the utilisation of the Lending Pool.
    InterestRateConfiguration public interestRateConfig;

    /**
     * A struct with the set of interest rate configuration parameters:
     * - baseRatePerYear The interest rate when utilisation is 0.
     * - lowSlopePerYear The slope of the first curve, defined as the delta in interest rate for a delta in utilisation of 100%.
     * - highSlopePerYear The slope of the second curve, defined as the delta in interest rate for a delta in utilisation of 100%.
     * - utilisationThreshold the optimal utilisation, where we go from the flat first curve to the steeper second curve.
     */
    struct InterestRateConfiguration {
        uint72 baseRatePerYear; //18 decimals precision.
        uint72 lowSlopePerYear; //18 decimals precision.
        uint72 highSlopePerYear; //18 decimals precision.
        uint40 utilisationThreshold; //5 decimal precision.
    }

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event InterestRate(uint80 interestRate);

    /* //////////////////////////////////////////////////////////////
                        INTEREST RATE LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Sets the configuration parameters of InterestRateConfiguration struct.
     * @param newConfig A struct with a new set of interest rate configuration parameters:
     * - baseRatePerYear The interest rate when utilisation is 0, 18 decimals precision.
     * - lowSlopePerYear The slope of the first curve, defined as the delta in interest rate for a delta in utilisation of 100%,
     *   18 decimals precision.
     * - highSlopePerYear The slope of the second curve, defined as the delta in interest rate for a delta in utilisation of 100%,
     *   18 decimals precision.
     * - utilisationThreshold the optimal utilisation, where we go from the flat first curve to the steeper second curve,
     *   5 decimal precision.
     */
    function _setInterestConfig(InterestRateConfiguration calldata newConfig) internal {
        interestRateConfig = newConfig;
    }

    /**
     * @notice Calculates the interest rate.
     * @param utilisation Utilisation rate, 5 decimal precision.
     * @return interestRate The current interest rate, 18 decimal precision.
     * @dev The interest rate is a function of the utilisation of the Lending Pool.
     * We use two linear curves: a flat one below the optimal utilisation and a steep one above.
     */
    function _calculateInterestRate(uint256 utilisation) internal view returns (uint256) {
        unchecked {
            if (utilisation >= interestRateConfig.utilisationThreshold) {
                // 1e23 = uT (1e5) * ls (1e18).
                uint256 lowSlopeInterest =
                    uint256(interestRateConfig.utilisationThreshold) * interestRateConfig.lowSlopePerYear;
                // 1e23 = (uT - u) (1e5) * hs (e18).
                uint256 highSlopeInterest = uint256((utilisation - interestRateConfig.utilisationThreshold))
                    * interestRateConfig.highSlopePerYear;
                // 1e18 = bs (1e18) + (lsIR (e23) + hsIR (1e23)) / 1e5.
                return uint256(interestRateConfig.baseRatePerYear) + ((lowSlopeInterest + highSlopeInterest) / 100_000);
            } else {
                // 1e18 = br (1e18) + (ls (1e18) * u (1e5)) / 1e5.
                return uint256(
                    uint256(interestRateConfig.baseRatePerYear)
                        + ((uint256(interestRateConfig.lowSlopePerYear) * utilisation) / 100_000)
                );
            }
        }
    }

    /**
     * @notice Updates the interest rate.
     * @param totalDebt Total amount of debt.
     * @param totalLiquidity Total amount of Liquidity (sum of borrowed out assets and assets still available in the Lending Pool).
     * @dev This function is only be called by the function _updateInterestRate(uint256 realisedDebt_, uint256 totalRealisedLiquidity_),
     * calculates the interest rate, if the totalRealisedLiquidity_ is zero then utilisation is zero.
     */
    function _updateInterestRate(uint256 totalDebt, uint256 totalLiquidity) internal {
        uint256 utilisation; // 5 decimals precision
        if (totalLiquidity > 0) {
            utilisation = (100_000 * totalDebt) / totalLiquidity;
        }

        //Calculates and stores interestRate as a uint256, emits interestRate as a uint80 (interestRate is maximally equal to uint72 + uint72).
        //_updateInterestRate() will be called a lot, saves a read from from storage or a write+read from memory.
        emit InterestRate(uint80(interestRate = _calculateInterestRate(utilisation)));
    }
}