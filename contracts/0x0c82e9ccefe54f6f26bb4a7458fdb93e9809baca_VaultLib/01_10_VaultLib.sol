// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

// interfaces
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IWhitelistManager} from "../interfaces/IWhitelistManager.sol";

import "../config/constants.sol";
import "../config/types.sol";
import "../config/errors.sol";

library VaultLib {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Transfers assets between account holder and vault
     */
    function transferAssets(
        uint256 primaryDeposit,
        Collateral[] calldata collaterals,
        uint256[] calldata roundStartingBalances,
        address recipient
    ) external returns (uint256[] memory amounts) {
        // primary asset amount used to calculating the amount of secondary assets deposited in the round
        uint256 primaryTotal = roundStartingBalances[0];

        bool isWithdraw = recipient != address(this);

        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = roundStartingBalances[i];

            if (isWithdraw) {
                amounts[i] = balance.mulDivDown(primaryDeposit, primaryTotal);
            } else {
                amounts[i] = balance.mulDivUp(primaryDeposit, primaryTotal);
            }

            if (amounts[i] != 0) {
                if (isWithdraw) {
                    IERC20(collaterals[i].addr).safeTransfer(recipient, amounts[i]);
                } else {
                    IERC20(collaterals[i].addr).safeTransferFrom(msg.sender, recipient, amounts[i]);
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Rebalances assets
     * @dev will only allow surplus assets to be exchanged
     */
    function rebalance(address otc, uint256[] calldata amounts, Collateral[] calldata collaterals, address whitelist) external {
        if (collaterals.length != amounts.length) revert VL_DifferentLengths();

        if (!IWhitelistManager(whitelist).isOTC(otc)) revert Unauthorized();

        for (uint256 i; i < collaterals.length;) {
            if (amounts[i] != 0) {
                IERC20 asset = IERC20(collaterals[i].addr);

                if (amounts[i] > asset.balanceOf(address(this))) revert VL_ExceedsSurplus();

                asset.safeTransfer(otc, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Processes withdrawing assets based on shares
     * @dev used to send assets to the pauser at the end of each round
     */
    function withdrawWithShares(Collateral[] calldata collaterals, uint256 totalSupply, uint256 shares, address recipient)
        external
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            uint256 balance = IERC20(collaterals[i].addr).balanceOf(address(this));

            amounts[i] = balance.mulDivDown(shares, totalSupply);

            if (amounts[i] != 0) {
                IERC20(collaterals[i].addr).safeTransfer(recipient, amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Gets the next option expiry from the given timestamp
     * @param roundConfig the configuration used to calculate the option expiry
     */
    function getNextExpiry(RoundConfig storage roundConfig) internal view returns (uint256 nextTime) {
        uint256 offset = block.timestamp + roundConfig.duration;

        // The offset will always be greater than the options expiry,
        // so we subtract a week in order to get the day the option should expire,
        // or subtract a day to get the hour the option should start if the dayOfWeek is wild (8)
        if (roundConfig.dayOfWeek != 8) offset -= 1 weeks;
        else offset -= 1 days;

        nextTime = _getNextDayTimeOfWeek(offset, roundConfig.dayOfWeek, roundConfig.hourOfDay);

        //if timestamp is in the past relative to the offset,
        // it means we've tried to calculate an expiry of an option which has too short of length.
        // I.e trying to run a 1 day option on a Tuesday which should expire Friday
        if (nextTime < offset) revert SL_BadExpiryDate();
    }

    /**
     * @notice Calculates the next day/hour of the week
     * @param timestamp is the expiry timestamp of the current option
     * @param dayOfWeek is the day of the week we're looking for (sun:0/7 - sat:6),
     *                  8 will be treated as disabled and the next available hourOfDay will be returned
     * @param hourOfDay is the next hour of the day we want to expire on (midnight:0)
     *
     * Examples when day = 5, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday) -> week 2 friday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 2 friday:0800
     *
     * Examples when day = 7, hour = 8:
     * getNextDayTimeOfWeek(week 1 thursday) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0500) -> week 1 friday:0800
     * getNextDayTimeOfWeek(week 1 friday:0900) -> week 1 saturday:0800
     * getNextDayTimeOfWeek(week 1 saturday) -> week 1 sunday:0800
     */
    function _getNextDayTimeOfWeek(uint256 timestamp, uint256 dayOfWeek, uint256 hourOfDay)
        internal
        pure
        returns (uint256 nextStartTime)
    {
        // we want sunday to have a value of 7
        if (dayOfWeek == 0) dayOfWeek = 7;

        // dayOfWeek = 0 (sunday) - 6 (saturday) calculated from epoch time
        uint256 timestampDayOfWeek = ((timestamp / 1 days) + 4) % 7;
        //Calculate the nextDayOfWeek by figuring out how much time is between now and then in seconds
        uint256 nextDayOfWeek =
            timestamp + ((7 + (dayOfWeek == 8 ? timestampDayOfWeek : dayOfWeek) - timestampDayOfWeek) % 7) * 1 days;
        //Calculate the nextStartTime by removing the seconds past midnight, then adding the amount seconds after midnight we wish to start
        nextStartTime = nextDayOfWeek - (nextDayOfWeek % 24 hours) + (hourOfDay * 1 hours);

        // If the date has passed, we simply increment it by a week to get the next dayOfWeek, or by a day if we only want the next hourOfDay
        if (timestamp >= nextStartTime) {
            if (dayOfWeek == 8) nextStartTime += 1 days;
            else nextStartTime += 7 days;
        }
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param initParams is the struct with vault general data
     */
    function verifyInitializerParams(InitParams calldata initParams) external pure {
        if (initParams._owner == address(0)) revert VL_BadOwnerAddress();
        if (initParams._manager == address(0)) revert VL_BadManagerAddress();
        if (initParams._feeRecipient == address(0)) revert VL_BadFeeAddress();
        if (initParams._oracle == address(0)) revert VL_BadOracleAddress();
        if (initParams._pauser == address(0)) revert VL_BadPauserAddress();
        if (initParams._performanceFee > 100 * PERCENT_MULTIPLIER || initParams._managementFee > 100 * PERCENT_MULTIPLIER) {
            revert VL_BadFee();
        }

        if (initParams._collaterals.length == 0) revert VL_BadCollateral();
        for (uint256 i; i < initParams._collaterals.length;) {
            if (initParams._collaterals[i].addr == address(0)) revert VL_BadCollateralAddress();

            unchecked {
                ++i;
            }
        }
        if (initParams._collateralRatios.length > 0) {
            if (initParams._collateralRatios.length != initParams._collaterals.length) revert BV_BadRatios();
        }

        if (
            initParams._roundConfig.duration == 0 || initParams._roundConfig.dayOfWeek > 8
                || initParams._roundConfig.hourOfDay > 23
        ) revert VL_BadDuration();
    }
}