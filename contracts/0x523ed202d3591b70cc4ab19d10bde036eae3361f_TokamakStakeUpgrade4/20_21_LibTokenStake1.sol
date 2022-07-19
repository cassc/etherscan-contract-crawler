//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibTokenStake1 {
    enum DefiStatus {
        NONE,
        APPROVE,
        DEPOSITED,
        REQUESTWITHDRAW,
        REQUESTWITHDRAWALL,
        WITHDRAW,
        END
    }
    struct DefiInfo {
        string name;
        address router;
        address ext1;
        address ext2;
        uint256 fee;
        address routerV2;
    }
    struct StakeInfo {
        string name;
        uint256 startBlock;
        uint256 endBlock;
        uint256 balance;
        uint256 totalRewardAmount;
        uint256 claimRewardAmount;
    }

    struct StakedAmount {
        uint256 amount;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
        uint256 releasedTOSAmount;
        bool released;
    }

    struct StakedAmountForSTOS {
        uint256 amount;
        uint256 startBlock;
        uint256 periodBlock;
        uint256 rewardPerBlock;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
    }
}