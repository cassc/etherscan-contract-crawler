// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ILevelManager {
    struct Tier {
        string id;
        uint256 multiplier; // 3 decimals. 1x = 1000
        uint256 lockingPeriod; // in seconds
        uint256 minAmount; // tier is applied when userAmount >= minAmount
        bool random;
        uint8 odds; // divider: 2 = 50%, 4 = 25%, 10 = 10%
        bool vip; // tier is reachable only in "isVip" pools?
        bool aag; // tier gives AAG, if staked in "isAAG" pools?
    }
    
    struct Pool {
        address addr;
        bool enabled;
        // Final tokens amount = staked tokens amount * multiplier
        uint256 multiplier;
        bool isVip; // staking in this pool allows to get a VIP level?
        bool isAAG; // staking in this pool gives AAG?
        // AAG is enabled if level multiplier is >= X. e.g. higher levels can get AAG in lower pools
        uint256 minAAGLevelMultiplier;
        // Final lottery tier multiplier = level.multiplier * multiplierLottery. 10% = 100
        uint256 multiplierLotteryBoost;
        // Final guaranteed tier multiplier = level.multiplier * multiplierBoost. 10% = 100
        uint256 multiplierGuaranteedBoost;
        // Final AAG tier multiplier * multiplierAAGBoost. 10% = 100
        uint256 multiplierAAGBoost;
    }
    
    function getAlwaysRegister()
    external
    view
    returns (
        address[] memory,
        string[] memory,
        uint256[] memory
    );
    
    function getUserUnlockTime(address account) external view returns (uint256);
    
    function getTierById(string calldata id)
    external
    view
    returns (Tier memory);
    
    function getUserTier(address account) external view returns (Tier memory);
    
    // AAG level is when user:
    // - stakes in selected pools "pool.isAAG"
    // - has a specified level "tier.aag"
    // pool.isAAG && tier.aag (staked in that pool)
    function getIsUserAAG(address account) external view returns (bool);
    
    function getTierIds() external view returns (string[] memory);
    
    function lock(address account, uint256 startTime) external;
}