// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IGymSinglePool {
    struct UserInfo {
        uint256 totalDepositTokens;
        uint256 totalDepositDollarValue;
        uint256 totalGGYMNET;
        uint256 level;
        uint256 depositId;
        uint256 totalClaimt;
    }

    function getUserInfo(address) external view returns (UserInfo memory);

    function pendingRewardTotal(address) external view returns (uint256);

    function getUserLevelInSinglePool(address) external view returns (uint32);

    function totalGGymnetInPoolLocked() external view returns (uint256);

    function depositFromOtherContract(
        uint256,
        uint8,
        bool,
        address
    ) external;
}