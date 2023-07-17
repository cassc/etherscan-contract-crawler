// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase
// solhint-disable func-name-mixedcase

pragma solidity 0.8.9;

interface IConvexFraxPoolRegistry {
    function poolInfo(
        uint256
    )
        external
        view
        returns (
            address implementation,
            address stakingAddress,
            address stakingToken,
            address rewardsAddress,
            uint8 active
        );
}

interface IVaultRegistry {
    function createVault(uint256 _pid) external returns (address);
}

interface IProxyVault {
    function initialize(
        address _owner,
        address _stakingAddress,
        address _stakingToken,
        address _rewardsAddress
    ) external;

    function usingProxy() external returns (address);

    function owner() external returns (address);

    function stakingAddress() external returns (address);

    function rewards() external returns (address);

    function getReward() external;

    function getReward(bool _claim) external;

    function getReward(bool _claim, address[] calldata _rewardTokenList) external;

    function earned() external view returns (address[] memory token_addresses, uint256[] memory total_earned);
}

interface IStakingProxyBase is IProxyVault {
    //farming contract
    function stakingAddress() external view returns (address);

    //farming token
    function stakingToken() external view returns (address);

    function vaultVersion() external pure returns (uint256);
}

interface IStakingProxyConvex is IStakingProxyBase {
    function curveLpToken() external view returns (address);

    function convexDepositToken() external view returns (address);

    //create a new locked state of _secs timelength with a Curve LP token
    function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

    //create a new locked state of _secs timelength with a Convex deposit token
    function stakeLockedConvexToken(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

    //create a new locked state of _secs timelength
    function stakeLocked(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

    //add to a current lock
    function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external;

    //add to a current lock
    function lockAdditionalCurveLp(bytes32 _kek_id, uint256 _addl_liq) external;

    //add to a current lock
    function lockAdditionalConvexToken(bytes32 _kek_id, uint256 _addl_liq) external;

    // Extends the lock of an existing stake
    function lockLonger(bytes32 _kek_id, uint256 new_ending_ts) external;

    //withdraw a staked position
    //frax farm transfers first before updating farm state so will checkpoint during transfer
    function withdrawLocked(bytes32 _kek_id) external;

    //withdraw a staked position
    //frax farm transfers first before updating farm state so will checkpoint during transfer
    function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

    //helper function to combine earned tokens on staking contract and any tokens that are on this vault
    function earned() external view override returns (address[] memory token_addresses, uint256[] memory total_earned);
}

interface IFraxFarmERC20 {
    event StakeLocked(address indexed user, uint256 amount, uint256 secs, bytes32 kek_id, address source_address);

    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function owner() external view returns (address);

    function stakingToken() external view returns (address);

    function fraxPerLPToken() external view returns (uint256);

    function calcCurCombinedWeight(
        address account
    ) external view returns (uint256 old_combined_weight, uint256 new_vefxs_multiplier, uint256 new_combined_weight);

    function lockedStakesOf(address account) external view returns (LockedStake[] memory);

    function lockedStakesOfLength(address account) external view returns (uint256);

    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;

    function lockLonger(bytes32 kek_id, uint256 new_ending_ts) external;

    function stakeLocked(uint256 liquidity, uint256 secs) external returns (bytes32);

    function withdrawLocked(bytes32 kek_id, address destination_address) external returns (uint256);

    function periodFinish() external view returns (uint256);

    function getAllRewardTokens() external view returns (address[] memory);

    function earned(address account) external view returns (uint256[] memory new_earned);

    function totalLiquidityLocked() external view returns (uint256);

    function lockedLiquidityOf(address account) external view returns (uint256);

    function totalCombinedWeight() external view returns (uint256);

    function combinedWeightOf(address account) external view returns (uint256);

    function lockMultiplier(uint256 secs) external view returns (uint256);

    function lock_time_min() external view returns (uint256);

    function rewardRates(uint256 token_idx) external view returns (uint256 rwd_rate);

    function userStakedFrax(address account) external view returns (uint256);

    function proxyStakedFrax(address proxy_address) external view returns (uint256);

    function maxLPForMaxBoost(address account) external view returns (uint256);

    function minVeFXSForMaxBoost(address account) external view returns (uint256);

    function minVeFXSForMaxBoostProxy(address proxy_address) external view returns (uint256);

    function veFXSMultiplier(address account) external view returns (uint256 vefxs_multiplier);

    function toggleValidVeFXSProxy(address proxy_address) external;

    function proxyToggleStaker(address staker_address) external;

    function stakerSetVeFXSProxy(address proxy_address) external;

    function getReward(address destination_address) external returns (uint256[] memory);

    function vefxs_max_multiplier() external view returns (uint256);

    function vefxs_boost_scale_factor() external view returns (uint256);

    function vefxs_per_frax_for_max_boost() external view returns (uint256);

    function getProxyFor(address addr) external view returns (address);

    function sync() external;
}

interface IMultiReward {
    function poolId() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardTokenLength() external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address) external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);
}