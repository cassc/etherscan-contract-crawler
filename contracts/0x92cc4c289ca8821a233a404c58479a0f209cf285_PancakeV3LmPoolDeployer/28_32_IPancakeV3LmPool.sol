// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IPancakeV3LmPool {
    function accumulateReward(uint32 currTimestamp) external;

    function crossLmTick(int24 tick, bool zeroForOne) external;

    function initialize() external;
}