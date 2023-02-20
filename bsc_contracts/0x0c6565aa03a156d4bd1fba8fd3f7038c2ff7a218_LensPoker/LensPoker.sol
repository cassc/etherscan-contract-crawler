/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMasterWombat {
    struct PoolInfo {
        // storage slot 1
        address lpToken; // Address of LP token contract.
        uint96 allocPoint; // How many allocation points assigned to this pool. WOMs to distribute per second.
        // storage slot 2
        address rewarder;
        // storage slot 3
        uint256 sumOfFactors; // the sum of all boosted factors by all of the users in the pool
        // storage slot 4
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOMs per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point.accumulated wom per factor share
        uint40 lastRewardTimestamp; // Last timestamp that WOMs distribution occurs.
    }

    struct PoolInfoV3 {
        address lpToken; // Address of LP token contract.
        ////
        address rewarder;
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        ////
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOM per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point. Accumulated WOM per factor share
        uint40 lastRewardTimestamp;
    }

    // Info of each user.
    struct UserInfo {
        // storage slot 1
        uint128 amount; // 20.18 fixed point. How many LP tokens the user has provided.
        uint128 factor; // 20.18 fixed point. boosted factor = sqrt (lpAmount * veWom.balanceOf())
        // storage slot 2
        uint128 rewardDebt; // 20.18 fixed point. Reward debt. See explanation below.
        uint128 pendingWom; // 20.18 fixed point. Amount of pending wom
    }

    function poolInfo(uint256 _index) external view returns (PoolInfo memory);
    function poolInfoV3(uint256 _index) external view returns (PoolInfoV3 memory);
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);
}

interface IVotingProxy {
    function lpTokenToPid(address gague, address lptoken) external view returns (uint256 pid);
}

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        bool shutdown;
    }
    function poolInfo(uint256 _index) external view returns (PoolInfo memory);
    function crvLockRewards() external view returns (address);
    function poolLength() external view returns (uint256);
}

interface IBaseRewardPool4626 {
    struct RewardState {
        address token;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 currentRewards;
        uint256 historicalRewards;
        bool paused;
    }

    function claimableRewards(address _account)
        external view returns (address[] memory tokens, uint256[] memory amounts);
    function tokenRewards(address _rewardToken)
        external view returns (RewardState memory);
}

contract LensPoker {
    address internal constant WOM_TOKEN = 0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1;
    address internal constant WMX_BOOSTER = 0x561050FFB188420D2605714F84EdA714DA58da69;
    address internal constant WMX_VOTING_PROXY = 0xE3a7FB9C6790b02Dcfa03B6ED9cda38710413569;
    address internal constant WOM_MASTER_WOMBAT = 0x489833311676B566f888119c29bd997Dc6C95830;

    function getPoolsToPoke1() public view returns(uint256[] memory) {
        return getPokeRequiredPoolIds(false);
    }
    function getPoolsToPoke2() public view returns(uint256[] memory) {
        return getPokeRequiredPoolIds(true);
    }

    function getPokeRequiredPoolIds(bool checkPeriodFinished) public view returns(uint256[] memory) {
        uint256 len = IBooster(WMX_BOOSTER).poolLength();
        uint256 requiredLen = 0;
        bool[] memory pokeRequired = new bool[](len);

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = IBooster(WMX_BOOSTER).poolInfo(i);

            // 0. Ignore if the pool is shut down
            if (poolInfo.shutdown) {
                continue;
            }

            // 1. Ignore if reward distribution paused
            uint256 womPid = IVotingProxy(WMX_VOTING_PROXY).lpTokenToPid(poolInfo.gauge, poolInfo.lptoken);
            IMasterWombat.PoolInfoV3 memory womPoolInfoV3 = IMasterWombat(WOM_MASTER_WOMBAT).poolInfoV3(womPid);
            if (womPoolInfoV3.rewardRate == 0 &&
                IMasterWombat(WOM_MASTER_WOMBAT).userInfo(womPid, WMX_VOTING_PROXY).pendingWom == 0) {
                continue;
            }

            if (checkPeriodFinished) {
                // 2. Ignore if periodFinished is not happened yet
                uint256 periodFinish = IBaseRewardPool4626(poolInfo.crvRewards).tokenRewards(WOM_TOKEN).periodFinish;
                if (periodFinish > block.timestamp) {
                    continue;
                }
            }

            // Push to the results list
            pokeRequired[i] = true;
            requiredLen++;
        }

        uint256[] memory result = new uint256[](requiredLen);
        uint256 j = 0;

        for (uint256 i = 0; i < len; i++) {
            if (pokeRequired[i]) {
                result[j++] = i;
            }
        }

        return result;
    }
}