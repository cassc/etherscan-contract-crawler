// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolDoHardWork {
    /* ========== EVENTS ========== */

    event DoHardWorkStrategyCompleted(address indexed strat, uint256 indexed index);
}