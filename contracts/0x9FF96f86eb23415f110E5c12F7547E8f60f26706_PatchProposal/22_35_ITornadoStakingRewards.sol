// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ITornadoStakingRewards {
    function updateRewardsOnLockedBalanceChange(address account, uint256 amountLockedBeforehand) external;
}