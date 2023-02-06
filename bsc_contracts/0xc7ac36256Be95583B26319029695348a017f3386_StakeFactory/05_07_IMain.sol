// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMain {
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }
    struct StakeInfo {
        uint256 term;
        uint256 maturityTs;
        uint256 amount;
        uint256 apy;
    }
    function fee() external returns(uint);
    function claimRank(uint256 term) external payable;
    function claimMintReward() external payable;
    function userMints(address user) external view returns(MintInfo memory);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function getMintReward(uint256 cRank,
        uint256 term,
        uint256 maturityTs,
        uint256 amplifier,
        uint256 eeaRate) external view returns(uint);

    function userStakes(address user) external view returns(StakeInfo memory);
    function claimMintRewardAndStake(uint256 pct, uint256 term) external payable;
    function stake(uint256 amount, uint256 term) external payable;
    function withdraw() external payable;
}