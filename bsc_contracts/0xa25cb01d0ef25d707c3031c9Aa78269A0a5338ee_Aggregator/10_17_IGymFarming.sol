// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGymFarming {
    struct UserInfo {
        uint256 totalDepositTokens;
        uint256 totalDepositDollarValue;
        uint256 lpTokensAmount;
        uint256 rewardDebt;
        uint256 totalClaims;
    }

    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    function getUserInfo(uint256, address) external view returns (UserInfo memory);
    function getUserUsdDepositAllPools(address) external view returns (uint256);
    function depositFromOtherContract(uint256, uint256, address) external;
    function pendingRewardTotal(address) external view returns (uint256 total);
    function isSpecialOfferParticipant(address _user) external view returns (bool);
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256, address) external view returns(UserInfo memory);
    function getRewardPerBlock() external view returns (uint256);

}