// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IHook {
    // uses in initialing. fo example to link hook and caller of this hook
    function setupCaller() external;

    function onClaim(address account) external;

    function onUnstake(address instance, address account, uint64 duration, uint256 amount, uint64 rewardsFraction) external;


}