// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

// Define Booster Interface
interface IAuraBooster {
    function deposit(
        uint256 pid_,
        uint256 amount_,
        bool stake_
    ) external returns (bool);
}

// Define Base Reward Pool interface
interface IAuraRewardPool {
    function balanceOf(address account_) external view returns (uint256);

    function earned(address account_) external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 index) external view returns (address);

    function deposit(uint256 assets_, address receiver_) external;

    function getReward(address account_, bool claimExtras_) external;

    function withdrawAndUnwrap(uint256 amount_, bool claim_) external returns (bool);
}

// Define Aura Mining Lib interface
interface IAuraMiningLib {
    function convertCrvToCvx(uint256 amount_) external view returns (uint256);
}

// Define Aura STASH Token Interface
interface ISTASHToken {
    function baseToken() external view returns (address);
}