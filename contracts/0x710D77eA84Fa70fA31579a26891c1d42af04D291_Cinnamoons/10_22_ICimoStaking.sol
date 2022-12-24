// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface ICimoStaking {
    
    struct UserInfo {
        uint16 nftBoost; //NFT token multiplier
        uint16 lockTimeBoost; //time lock multiplier - max x3
        uint32 lockedUntil; //lock end in UNIX seconds, used to compute the lockTimeBoost
        uint96 claimableETH; //amount of eth ready to be claimed
        uint112 amount; //amount of staked tokens
        uint112 weightedBalance; //amout of staked tokens * multiplier * nftMultiplier
        uint256 withdrawn; //sum of withdrawn ETH
        uint112 ETHrewardDebt; //ETH debt for each staking session. Session resets upon withdrawal
        address[] NFTContracts; //array of nft contracts (for multiple NFTcontract boost
        uint256[] NFTTokenIDs; //nft id tracker
    }
}