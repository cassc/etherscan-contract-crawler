/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

pragma solidity ^0.8.0;

interface IUserInfo {
    function userInfo(address _user) external view returns (uint256 shares, uint256 lastDepositedTime, uint256 cakeAtLastUserAction, uint256 lastUserActionTime, uint256 lockStartTime, uint256 lockEndTime, uint256 userBoostedShare, bool locked, uint256 lockedAmount);
}

contract UserInfoChecker {
    struct UserInfo {
        address userAddress;
        uint256 lockedAmount;
        uint256 lockEndTime;
        bool locked;
    }

    function checkUserInfo(address[] calldata userAddresses) external view returns (uint256, UserInfo[] memory) {
        IUserInfo userInfoContract = IUserInfo(0x45c54210128a065de780C4B0Df3d16664f7f859e);
        uint256 userCount = userAddresses.length;
        UserInfo[] memory results = new UserInfo[](userCount);
        uint256 validResultsCount = 0;
        for (uint256 i = 0; i < userCount; i++) {
            address userAddress = userAddresses[i];
            (, , , , uint256 lockStartTime, uint256 lockEndTime, , bool locked, uint256 lockedAmount) = userInfoContract.userInfo(userAddress);
            if (lockedAmount > 0) {
                results[validResultsCount] = UserInfo(userAddress, lockedAmount, lockEndTime, locked);
                validResultsCount++;
            }
        }
        UserInfo[] memory validResults = new UserInfo[](validResultsCount);
        for (uint256 i = 0; i < validResultsCount; i++) {
            validResults[i] = results[i];
        }
        return (validResultsCount, validResults);
    }
}