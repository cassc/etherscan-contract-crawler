// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IVault {

    struct UserInfo {
        uint256 shares;
        uint256 rewardDebt;
        uint256 dollarValue;
        uint256 totalClaims;
    }

    function getRewardPerBlock() external view returns (uint256);
    function userInvestment(uint256,address) external view returns (uint256);
    function pendingReward(uint256,address) external view returns (uint256);
    function getUserDepositDollarValue(address) external view returns (uint256);
    function isEmailVerified(address) external view returns (bool);
    function getUserInvestment(address) external view returns (bool);
    function userInfo(uint256, address) external view returns (UserInfo memory);


}