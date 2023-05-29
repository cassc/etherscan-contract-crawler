// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISpotStorage {
    /// @notice Enum to describe the trading status of the vault
    /// @dev NOT_OPENED - Not open
    /// @dev OPENED - opened position
    /// @dev CANCELLED_WITH_ZERO_RAISE - cancelled without any raise
    /// @dev CANCELLED_WITH_NO_FILL - cancelled with raise but not opening a position
    /// @dev CANCELLED_BY_MANAGER - cancelled by the manager after raising
    /// @dev DISTRIBUTED - closed position and distributed fees
    enum StfStatus {
        NOT_OPENED,
        OPENED,
        CANCELLED_WITH_ZERO_RAISE,
        CANCELLED_WITH_NO_FILL,
        CANCELLED_BY_MANAGER,
        DISTRIBUTED
    }

    struct StfSpot {
        address baseToken;
        address depositToken;
        uint40 fundraisingPeriod;
    }

    struct StfSpotInfo {
        StfStatus status;
        address manager;
        uint40 endTime;
        uint40 fundDeadline;
        uint96 totalRaised;
        uint96 totalAmountUsed;
        uint96 totalReceived;
        uint96 remainingAfterFees;
        address baseToken;
        address depositToken;
    }
}