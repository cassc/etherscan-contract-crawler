// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDrFrankenstein {
    struct UserInfoDrFrankenstien {
        uint256 amount;                 // How many LP tokens the user has provided.
        uint256 rewardDebt;             // Reward debt. See explanation below.
        uint256 tokenWithdrawalDate;    // Date user must wait until before early withdrawal fees are lifted.
        // User grave info
        uint256 rugDeposited;               // How many rugged tokens the user deposited.
        bool paidUnlockFee;                 // true if user paid the unlock fee.
        uint256  nftRevivalDate;            // Date user must wait until before harvesting their nft.
    }

    struct PoolInfoDrFrankenstein {
        address lpToken;                        // Address of LP token contract.
        uint256 allocPoint;                     // How many allocation points assigned to this pool. ZMBEs to distribute per block.
        uint256 lastRewardBlock;                // Last block number that ZMBEs distribution occurs.
        uint256 accZombiePerShare;              // Accumulated ZMBEs per share, times 1e12. See below.
        uint256 minimumStakingTime;             // Duration a user must stake before early withdrawal fee is lifted.
        // Grave variables
        bool isGrave;                           // True if pool is a grave (provides nft rewards).
        bool requiresRug;                       // True if grave require a rugged token deposit before unlocking.
        address ruggedToken;                    // Address of the grave's rugged token (casted to IGraveStakingToken over IBEP20 to save space).
        address nft;                            // Address of reward nft.
        uint256 unlockFee;                      // Unlock fee (In BUSD, Chainlink Oracle is used to convert fee to current BNB value).
        uint256 minimumStake;                   // Minimum amount of lpTokens required to stake.
        uint256 nftRevivalTime;                 // Duration a user must stake before they can redeem their nft reward.
        uint256 unlocks;                        // Number of times a grave is unlocked
    }

    function poolLength() external view returns (uint256);
    function userInfo(uint pid, address userAddress) external view returns (UserInfoDrFrankenstien memory);
    function poolInfo(uint pid) external view returns (PoolInfoDrFrankenstein memory);
}