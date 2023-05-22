// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {StandardSettings} from "./StandardSettings.sol";

contract StandardSettingsFactory {
    using ClonesWithImmutableArgs for address;

    event NewSettings(address indexed settingsAddress);

    error StandardSettingsFactory__RoyaltyTooHigh();
    error StandardSettingsFactory__TradeFeeTooHigh();
    error StandardSettingsFactory__LockDurationTooHigh();

    uint256 constant ONE_YEAR_SECS = 31_556_926;
    uint256 constant BASE = 10_000;

    StandardSettings immutable standardSettingsImplementation;

    constructor(StandardSettings _standardSettingsImplementation) {
        standardSettingsImplementation = _standardSettingsImplementation;
    }

    function createSettings(
        address payable settingsFeeRecipient,
        uint256 ethCost,
        uint64 secDuration,
        uint64 feeSplitBps,
        uint64 royaltyBps
    ) public returns (StandardSettings settings) {
        if (royaltyBps > (BASE / 10)) revert StandardSettingsFactory__RoyaltyTooHigh();
        if (feeSplitBps > BASE) revert StandardSettingsFactory__TradeFeeTooHigh();
        if (secDuration > ONE_YEAR_SECS) revert StandardSettingsFactory__LockDurationTooHigh();

        bytes memory data = abi.encodePacked(ethCost, secDuration, feeSplitBps, royaltyBps);
        settings = StandardSettings(address(standardSettingsImplementation).clone(data));
        settings.initialize(msg.sender, settingsFeeRecipient);
        emit NewSettings(address(settings));
    }
}