// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { VaultUtil } from "../libraries/VaultUtil.sol";
import { Vault } from "../libraries/Vault.sol";

contract TestVaultUtil {
    Vault.VaultState public vaultState;

    /**
     * @notice Calculates the next day/hour of the week
     * @param timestamp is the expiry timestamp of the current option
     * @param dayOfWeek is the day of the week we're looking for (sun:0/7 - sat:6), 8 will be treated as wil and the next available hourOfDay will be returned
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
    function getNextDayTimeOfWeek(uint256 timestamp, uint256 dayOfWeek, uint256 hourOfDay) internal pure returns (uint256) {
        // we want sunday to have a vaule of 7
        if (dayOfWeek == 0) dayOfWeek = 7;

        // dayOfWeek = 0 (sunday) - 6 (saturday) calculated from epoch time
        uint256 timestampDayOfWeek = ((timestamp / 1 days) + 4) % 7;
        //Calculate the nextDayOfWeek by figuring out how much time is between now and then in seconds
        uint256 nextDayOfWeek =
            timestamp + ((7 + (dayOfWeek == 8 ? timestampDayOfWeek : dayOfWeek) - timestampDayOfWeek) % 7) * 1 days;
        //Calculate the nextStartTime by removing the seconds past midnight, then adding the amount seconds after midnight we wish to start
        uint256 nextStartTime = nextDayOfWeek - (nextDayOfWeek % 24 hours) + (hourOfDay * 1 hours);

        // If the date has passed, we simply increment it by a week to get the next dayOfWeek, or by a day if we only want the next hourOfDay
        if (timestamp >= nextStartTime) {
            dayOfWeek == 8 ? nextStartTime += 1 days : nextStartTime += 7 days;
        }

        return nextStartTime;
    }

    /**
     * @notice Gets the next option expiry timestamp
     * @param roundConfig the configuration used to calculate the option expiry
     */
    function getNextExpiry(uint256 timestamp, Vault.RoundConfig calldata roundConfig) external pure returns (uint256) {
        uint256 offset = timestamp + roundConfig.duration;

        // The offset will always be greater than the options expiry, so we subtract a week in order to get the day the option should expire, or subtract a day to get the hour the option should start if the dayOfWeek is wild (8)
        if (roundConfig.dayOfWeek != 8) {
            offset -= 1 weeks;
        } else {
            offset -= 1 days;
        }

        uint256 nextTime = getNextDayTimeOfWeek(offset, roundConfig.dayOfWeek, roundConfig.hourOfDay);

        //if timestamp is in the past relative to the offset, it means we've tried to calculate an expiry of an option which has too short of length. I.e trying to run a 1 day option on a Tuesday which should expire Friday
        require(nextTime >= offset, "Option period is too short to land on the configured expiry date");

        return nextTime;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (account == address(this)) {
            return 1 ether;
        }
        return 0;
    }

    function setVaultState(Vault.VaultState calldata newVaultState) public {
        vaultState.totalPending = newVaultState.totalPending;
    }
}