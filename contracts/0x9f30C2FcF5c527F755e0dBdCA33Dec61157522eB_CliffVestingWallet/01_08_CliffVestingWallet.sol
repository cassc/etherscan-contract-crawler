// SPDX-License-Identifier: MIT
// Adapted from https://github.com/Uniswap/governance/blob/master/contracts/TreasuryVester.sol
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {VestingWalletUpgradeable} from "@openzeppelin/contracts-upgradeable-4.5.0/finance/VestingWalletUpgradeable.sol";

contract CliffVestingWallet is VestingWalletUpgradeable {
    uint64 private _cliff;

    function initialize(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffSeconds
    ) public initializer {
        require(
            cliffSeconds <= durationSeconds,
            "VestingWallet: cliff > duration"
        );
        __VestingWallet_init(
            beneficiaryAddress,
            startTimestamp,
            durationSeconds
        );
        _cliff = cliffSeconds;
    }

    function cliff() public view returns (uint256) {
        return _cliff;
    }

    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp)
        internal
        view
        override
        returns (uint256)
    {
        if (timestamp < start() + _cliff) {
            return 0;
        }
        return super._vestingSchedule(totalAllocation, timestamp);
    }
}