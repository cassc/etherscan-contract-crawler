/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IUserInfo {
    function userInfo(address _user) external view returns (uint256 shares, uint256 lastDepositedTime, uint256 cakeAtLastUserAction, uint256 lastUserActionTime, uint256 lockStartTime, uint256 lockEndTime, uint256 userBoostedShare, bool locked, uint256 lockedAmount);
}

contract UserInfoChecker {
    struct UserInfo {
        address userAddress;
        uint256 lockedAmount;
    }

    function checkUserInfo(address[] calldata userAddresses) external view returns (UserInfo[] memory) {
        IUserInfo userInfoContract = IUserInfo(0x45c54210128a065de780C4B0Df3d16664f7f859e);
        uint256 userCount = userAddresses.length;
        UserInfo[] memory results = new UserInfo[](userCount);
        for (uint256 i = 0; i < userCount; i++) {
            address userAddress = userAddresses[i];
            (, , , , , , , bool locked, uint256 lockedAmount) = userInfoContract.userInfo(userAddress);
            if (lockedAmount > 0) {
                results[i] = UserInfo(userAddress, lockedAmount);
            } else {
                results[i] = UserInfo(address(0), 0);
            }
        }
        return results;
    }
}