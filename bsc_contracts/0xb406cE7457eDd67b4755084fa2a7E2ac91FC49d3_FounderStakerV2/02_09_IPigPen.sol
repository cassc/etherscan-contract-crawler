// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPigPen {

    struct UserInfo {
        uint256 amount;
        uint256 busdRewardDebt;
        uint256 pigsRewardDebt;
        uint256 startLockTimestamp;
    }

    function deposit(uint256 _amount) external;
    function claimRewards(bool _shouldCompound) external;
    function withdraw() external;
    function emergencyWithdraw() external;

}