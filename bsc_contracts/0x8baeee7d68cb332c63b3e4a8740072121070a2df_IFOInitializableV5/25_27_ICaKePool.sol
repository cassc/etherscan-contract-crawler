// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ICaKePool {
    struct UserInfo {
        uint256 shares;
        uint256 lastDepositedTime;
        uint256 cakeAtLastUserAction;
        uint256 lastUserActionTime;
        uint256 lockStartTime;
        uint256 lockEndTime;
        uint256 userBoostedShare;
        bool locked;
        uint256 lockedAmount;
    }

    function userInfo(address _user) external view returns (UserInfo memory);
}