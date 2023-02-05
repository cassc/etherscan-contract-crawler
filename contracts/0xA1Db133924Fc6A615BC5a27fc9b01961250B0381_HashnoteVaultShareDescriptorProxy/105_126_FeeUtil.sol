// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";
import { SafeERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Vault } from "./Vault.sol";

import { IERC20 } from "../interfaces/IERC20.sol";
import { IOracle } from "../interfaces/GrappaInterfaces.sol";

import "./Errors.sol";

library FeeUtil {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev structure used in memory to close a round
     */
    struct CloseParams {
        uint256 currentShareSupply;
        uint256 queuedWithdrawShares;
        uint256 managementFee;
        uint256 performanceFee;
        address feeRecipient;
        address oracleAddr;
        Vault.Collateral[] collaterals;
        uint256[] roundStartingBalances;
        uint256 expiry;
    }

    /**
     * @notice Closes round by collecting fees, calculating PPS and number of new shares to mint
     * @param vaultState is the storage variable vaultState passed from HashnoteVault
     * @param params is the parameters passed to compute the next state
     * @return currentBalances is the balances of each asset at the start of the round
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     * @return totalFees is the amount of fees paid in each asset
     * @return perforamceFees is the amount of performance fees paid in each asset
     */
    function closeRound(Vault.VaultState storage vaultState, CloseParams calldata params)
        external
        returns (
            uint256[] memory currentBalances,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256[] memory totalFees,
            uint256[] memory perforamceFees
        )
    {
        uint256 currentNAV;
        uint256 pendingNAV;

        // calculate and transfer round fees
        (currentBalances, totalFees, perforamceFees) = processFees(params, vaultState.totalPending);

        // net asset value held by the vault and that of deposits pending inclusion (pendingNAV is a subset of currentNAV)
        (currentNAV, pendingNAV) = _calculateNAV(vaultState, params);

        // rounds price per share based on assets used in last round and total supply
        newPricePerShare = _pricePerShare(params.currentShareSupply, currentNAV, pendingNAV);

        // after settling positions, if the options expire in-the-money (ITM) vault PPS will go down due to decrease in NAV
        // newly minted shares do not take on the loss
        mintShares = _navToShares(pendingNAV, newPricePerShare);
    }

    /**
     * @notice Calculates the management and performance fee for the current round
     * @param params CloseParams passed to closeRound
     * @param pendingAmount is the pending deposit amount
     * @return currentBalances is the asset balances at the start of the next round
     * @return totalFees is the amounts paid in each asset
     * @return perforamceFees is the amounts paid in each asset
     */
    function processFees(CloseParams calldata params, uint256 pendingAmount)
        public
        returns (uint256[] memory currentBalances, uint256[] memory totalFees, uint256[] memory perforamceFees)
    {
        currentBalances = _getCurrentBalances(params.collaterals);

        totalFees = new uint256[](currentBalances.length);
        perforamceFees = new uint256[](currentBalances.length);

        // primary asset amount used to calculating the amount of secondary assets deposted in the round
        uint256 primaryTotal = params.roundStartingBalances[0];

        for (uint256 i; i < currentBalances.length;) {
            uint256 lockedBalanceSansPending;
            uint256 managementFeeInAsset;
            uint256 performanceFeeInAsset;

            uint256 currentBalance = currentBalances[i];

            uint256 pendingBalance = params.roundStartingBalances[i].mulDivDown(pendingAmount, primaryTotal);

            // At round 1, currentBalance == pendingAmount so we do not take fee on the first round
            if (currentBalance > pendingBalance) {
                lockedBalanceSansPending = currentBalance - pendingBalance;
            }

            managementFeeInAsset = lockedBalanceSansPending.mulDivDown(params.managementFee, 100 * Vault.FEE_MULTIPLIER);

            // Performance fee proceesed ONLY if difference between starting balance(s) and ending
            // balance(s) (excluding pending depositing) is positive
            // If the balance is negative, the the round did not profit.
            if (lockedBalanceSansPending > params.roundStartingBalances[i]) {
                if (params.performanceFee != 0) {
                    uint256 performanceAmount = lockedBalanceSansPending - params.roundStartingBalances[i];

                    performanceFeeInAsset = performanceAmount.mulDivDown(params.performanceFee, 100 * Vault.FEE_MULTIPLIER);

                    perforamceFees[i] = performanceFeeInAsset;
                }
            }

            totalFees[i] = managementFeeInAsset + performanceFeeInAsset;

            if (totalFees[i] != 0) {
                // deducting fees from current balances
                currentBalances[i] -= totalFees[i];

                IERC20(params.collaterals[i].addr).safeTransfer(params.feeRecipient, totalFees[i]);
            }

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
        Vault.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 navPerShare,
        uint256 depositNAV
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound = _navToShares(depositNAV, navPerShare);

            return uint256(depositReceipt.unredeemedShares) + sharesFromRound;
        }
        return depositReceipt.unredeemedShares;
    }

    /**
     * @notice calculates relative Net Asset Value based on the primary asset and a rounds starting balanace(s)
     * @dev used in pending deposits (per account and in aggregate)
     */
    function calculateRelativeNAV(
        address oracleAddr,
        Vault.Collateral[] calldata collaterals,
        uint256[] calldata roundStartingBalances,
        uint256 primaryDeposited,
        uint256 expiry
    ) public view returns (uint256 totalNAV) {
        // primary collateral addr, all other assets will be quotes in this
        address quote = collaterals[0].addr;

        // primary asset amount used to calculating the amount of secondary assets deposted in the round
        uint256 primaryTotal = roundStartingBalances[0];

        for (uint256 i; i < collaterals.length;) {
            uint256 price = Vault.UNIT;

            if (collaterals[i].addr != quote) {
                price = _getPrice(oracleAddr, collaterals[i].addr, quote, expiry);
            }

            uint256 balance = roundStartingBalances[i].mulDivDown(primaryDeposited, primaryTotal);

            totalNAV += price.mulDivDown(balance, 10 ** collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice calculates Net Asset Value of all the assets held by vault as well as the pending deposits
     */
    function _calculateNAV(Vault.VaultState storage vaultState, CloseParams calldata params)
        internal
        view
        returns (uint256 currentNAV, uint256 pendingNAV)
    {
        (currentNAV) = _calculateTotalBalanceNAV(params.oracleAddr, params.collaterals, params.expiry);

        pendingNAV = uint256(vaultState.totalPending);

        if (pendingNAV > 0) {
            pendingNAV = calculateRelativeNAV(
                params.oracleAddr, params.collaterals, params.roundStartingBalances, pendingNAV, params.expiry
            );
        }
    }

    /**
     * @notice calculates Net Asset Value of all the assets held by the vault
     * @dev this includes assts in the vault as well as pending deposits
     */
    function _calculateTotalBalanceNAV(address oracleAddr, Vault.Collateral[] calldata collaterals, uint256 expiry)
        internal
        view
        returns (uint256 totalNAV)
    {
        // primary asset that all other assets will be quotes in
        address quote = collaterals[0].addr;

        for (uint256 i; i < collaterals.length;) {
            uint256 price = Vault.UNIT;

            // if collateral is primary asset, leave price as 1 (scale 1e6)
            if (collaterals[i].addr != quote) {
                price = _getPrice(oracleAddr, collaterals[i].addr, quote, expiry);
            }

            uint256 balance = IERC20(collaterals[i].addr).balanceOf(address(this));

            // sum of all asset(s) NAV
            totalNAV += price.mulDivDown(balance, 10 ** collaterals[i].decimals);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Queries total balance(s) of collateral
     * @dev used in processFees
     */
    function _getCurrentBalances(Vault.Collateral[] calldata collaterals) internal view returns (uint256[] memory balances) {
        balances = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            balances[i] = IERC20(collaterals[i].addr).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice get spot price of base, denominated in quote.
     * @dev used in Net Asset Value calculations
     * @dev
     * @param oracleAddr Chainlink Oracle for Grappa options
     * @param base base asset. for ETH/USD price, ETH is the base asset
     * @param quote quote asset. for ETH/USD price, USD is the quote asset
     * @param expiry price at a given timestamp
     * @return price with 6 decimals
     */
    function _getPrice(address oracleAddr, address base, address quote, uint256 expiry) internal view returns (uint256 price) {
        IOracle oracle = IOracle(oracleAddr);

        // if timestamp is the placeholder (1) then get the spot
        if (expiry == Vault.PLACEHOLDER_UINT) {
            price = oracle.getSpotPrice(base, quote);
        } else {
            (price,) = oracle.getPriceAtExpiry(base, quote, expiry);
        }
    }

    function _navToShares(uint256 nav, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= Vault.PLACEHOLDER_UINT) revert FU_NPSLow();

        return nav.mulDivDown(Vault.UNIT, navPerShare);
    }

    function _sharesToNAV(uint256 shares, uint256 navPerShare) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        if (navPerShare <= Vault.PLACEHOLDER_UINT) revert FU_NPSLow();

        return shares.mulDivDown(navPerShare, Vault.UNIT);
    }

    function _pricePerShare(uint256 totalSupply, uint256 totalBalanceNAV, uint256 pendingNAV) internal pure returns (uint256) {
        return totalSupply > 0 ? (totalBalanceNAV - pendingNAV).mulDivDown(Vault.UNIT, totalSupply) : Vault.UNIT;
    }
}