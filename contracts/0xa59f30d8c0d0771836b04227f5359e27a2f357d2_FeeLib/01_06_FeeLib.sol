// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

// interfaces
import {IOracle} from "grappa/interfaces/IOracle.sol";

import "../config/constants.sol";
import "../config/errors.sol";
import "../config/types.sol";

library FeeLib {
    using FixedPointMathLib for uint256;

    /**
     * @notice Calculates the management and performance fee for the current round
     * @param vaultDetails VaultDetails struct
     * @param managementFee charged at each round
     * @param performanceFee charged if the vault performs
     * @return totalFees all fees taken in round
     * @return balances is the asset balances at the start of the next round
     */
    function processFees(VaultDetails calldata vaultDetails, uint256 managementFee, uint256 performanceFee)
        external
        pure
        returns (uint256[] memory totalFees, uint256[] memory balances)
    {
        uint256 arrayLength = vaultDetails.currentBalances.length;

        totalFees = new uint256[](arrayLength);
        balances = new uint256[](arrayLength);

        for (uint256 i; i < vaultDetails.currentBalances.length;) {
            uint256 lockedBalanceSansPending;
            uint256 managementFeeInAsset;
            uint256 performanceFeeInAsset;

            balances[i] = vaultDetails.currentBalances[i];

            // primary asset amount used to calculating the amount of secondary assets deposited in the round
            uint256 pendingBalance =
                vaultDetails.roundStartingBalances[i].mulDivDown(vaultDetails.totalPending, vaultDetails.roundStartingBalances[0]);

            // At round 1, currentBalance == totalPending so we do not take fee on the first round
            if (balances[i] > pendingBalance) {
                lockedBalanceSansPending = balances[i] - pendingBalance;
            }

            managementFeeInAsset = lockedBalanceSansPending.mulDivDown(managementFee, 100 * PERCENT_MULTIPLIER);

            // Performance fee charged ONLY if difference between starting balance(s) and ending
            // balance(s) (excluding pending depositing) is positive
            // If the balance is negative, the the round did not profit.
            if (lockedBalanceSansPending > vaultDetails.roundStartingBalances[i]) {
                if (performanceFee > 0) {
                    uint256 performanceAmount = lockedBalanceSansPending - vaultDetails.roundStartingBalances[i];

                    performanceFeeInAsset = performanceAmount.mulDivDown(performanceFee, 100 * PERCENT_MULTIPLIER);
                }
            }

            totalFees[i] = managementFeeInAsset + performanceFeeInAsset;

            // deducting fees from current balances
            balances[i] -= totalFees[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates Net Asset Value of the vault and pending deposits
     * @dev prices are based on expiry, if rolling close then spot is used
     * @param details NAVDetails struct
     * @return totalNav of all the assets
     * @return pendingNAV of just the pending assets
     * @return prices of the different assets
     */
    function calculateNAVs(NAVDetails calldata details)
        external
        view
        returns (uint256 totalNav, uint256 pendingNAV, uint256[] memory prices)
    {
        IOracle oracle = IOracle(details.oracleAddr);

        uint256 collateralLength = details.collaterals.length;

        prices = new uint256[](collateralLength);

        // primary asset that all other assets will be quotes in
        address quote = details.collaterals[0].addr;

        for (uint256 i; i < collateralLength;) {
            prices[i] = UNIT;

            // if collateral is primary asset, leave price as 1 (scale 1e6)
            if (i > 0) prices[i] = _getPrice(oracle, details.collaterals[i].addr, quote, details.expiry);

            // sum of all asset(s) value
            totalNav += details.currentBalances[i].mulDivDown(prices[i], 10 ** details.collaterals[i].decimals);

            // calculated pending deposit based on the primary asset
            uint256 pendingBalance = details.totalPending.mulDivDown(details.startingBalances[i], details.startingBalances[0]);

            // sum of pending assets value
            pendingNAV += pendingBalance.mulDivDown(prices[i], 10 ** details.collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice calculates relative Net Asset Value based on the primary asset and a rounds starting balance(s)
     * @dev used in pending deposits per account
     */
    function calculateRelativeNAV(
        Collateral[] memory collaterals,
        uint256[] memory roundStartingBalances,
        uint256[] memory collateralPrices,
        uint256 primaryDeposited
    ) external pure returns (uint256 nav) {
        // primary asset amount used to calculating the amount of secondary assets deposited in the round
        uint256 primaryTotal = roundStartingBalances[0];

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = roundStartingBalances[i].mulDivDown(primaryDeposited, primaryTotal);

            nav += balance.mulDivDown(collateralPrices[i], 10 ** collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param navPerShare is the price in asset per share
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 navPerShare,
        uint256 depositNAV
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound = navToShares(depositNAV, navPerShare);

            return uint256(depositReceipt.unredeemedShares) + sharesFromRound;
        }
        return depositReceipt.unredeemedShares;
    }

    function navToShares(uint256 nav, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= PLACEHOLDER_UINT) revert FL_NPSLow();

        return nav.mulDivDown(UNIT, navPerShare);
    }

    function pricePerShare(uint256 totalSupply, uint256 totalNAV, uint256 pendingNAV) internal pure returns (uint256) {
        return totalSupply > 0 ? (totalNAV - pendingNAV).mulDivDown(UNIT, totalSupply) : UNIT;
    }

    /**
     * @notice get spot price of base, denominated in quote.
     * @dev used in Net Asset Value calculations
     * @dev
     * @param oracle abstracted chainlink oracle
     * @param base base asset. for ETH/USD price, ETH is the base asset
     * @param quote quote asset. for ETH/USD price, USD is the quote asset
     * @param expiry price at a given timestamp
     * @return price with 6 decimals
     */
    function _getPrice(IOracle oracle, address base, address quote, uint256 expiry) internal view returns (uint256 price) {
        // if timestamp is the placeholder (1) or zero then get the spot
        if (expiry <= PLACEHOLDER_UINT) price = oracle.getSpotPrice(base, quote);
        else (price,) = oracle.getPriceAtExpiry(base, quote, expiry);
    }

    function _sharesToNAV(uint256 shares, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= PLACEHOLDER_UINT) revert FL_NPSLow();

        return shares.mulDivDown(navPerShare, UNIT);
    }
}