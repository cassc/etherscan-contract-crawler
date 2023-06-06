// SPDX-License-Identifier: MIT
// Original Copyright 2021 convex-eth
// Original source: https://github.com/convex-eth/platform/blob/669033cd06704fc67d63953078f42150420b6519/contracts/contracts/interfaces/IRewardHook.sol
pragma solidity 0.6.12;

interface IRewardHook {
    function onRewardClaim() external;
}