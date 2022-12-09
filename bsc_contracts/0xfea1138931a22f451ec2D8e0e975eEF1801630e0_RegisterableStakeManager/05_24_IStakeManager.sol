// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev Interface for freezing/staking certain token on the network
 */

// @todo rename to IStakeManager - check

interface IStakeManager {
    struct Plan {
        uint256 period;
        uint256 apy;
        uint256 emergencyTax;
        uint256 minimalAmount;
        bool active;
        uint256 pips;
    }

    struct Stake {
        address account;
        uint256 amount;
        uint256 depositTime;
        bytes32 planId;
        bool compound;
        uint256 compoundPeriod;
        uint256 lastWithdrawn;
    }

    struct StakeData {
        address account;
        bytes32 stakeId;
        uint256 amount;
        uint256 depositTime;
        uint256 depositBlock;
        bytes32 planId;
        bool compound;
        uint256 compoundPeriod;
        uint256 lastWithdrawn;
    }

    event Staked(
        address indexed account,
        uint256 amount,
        bytes32 planId,
        bytes32 indexed stakeId,
        uint256 timestamp,
        uint256 deadline,
        uint256 period,
        uint256 apy,
        uint256 emergencyTax,
        bool compound,
        address[] tokenForPair,
        uint256[] pricePerStable,
        bool[] stakedTokenMoreExpensive,
        uint256 pips
    );

    event Unstaked(
        address indexed account,
        uint256 stakedAmount,
        uint256 unstakedAmount,
        bytes32 planId,
        bytes32 stakeId,
        uint256 timestamp,
        uint256 deadline,
        uint256 period,
        uint256 apy,
        uint256 emergencyTax,
        bool compound,
        address[] tokenForPair,
        uint256[] pricePerStable,
        bool[] stakedTokenMoreExpensive,
        uint256 pips
    );

    event RewardsWithdrawn(
        address indexed account,
        uint256 rewards,
        bytes32 planId,
        bytes32 stakeId,
        uint256 amount,
        uint256 timestamp,
        address[] tokenForPair,
        uint256[] pricePerStable,
        bool[] stakedTokenMoreExpensive,
        uint256 pips
    );

    event EmergencyExited(
        address indexed account,
        uint256 staked,
        uint256 withdrawn,
        bytes32 planId,
        bytes32 stakeId,
        uint256 timestamp,
        uint256 deadline,
        uint256 period,
        uint256 apy,
        uint256 emergencyTax,
        bool compound,
        address[] tokenForPair,
        uint256[] pricePerStable,
        bool[] stakedTokenMoreExpensive,
        uint256 pips
    );

    event PlanSet(
        address indexed setter,
        bytes32 indexed planId,
        uint256 period,
        uint256 apy,
        uint256 emergencyTax,
        uint256 minimalAmount,
        uint256 pips
    );

    event PlanDisabled(
        address indexed setter,
        bytes32 indexed planId,
        uint256 period,
        uint256 apy,
        uint256 emergencyTax,
        uint256 pips
    );

    event PlanReactivated(address indexed setter, bytes32 indexed planId);
    event CompoundEnabled(address setter, bool enabled);
    event CompoundSet(address setter, uint256 period);
    event MaxTokensMinted(address setter, uint256 mintingAmount);
    event PricePairSet(address setter, address[] pricePairs);

    //Contract writing
    function stake(
        uint256 amount,
        bytes32 planId,
        bool compound
    ) external returns (bytes32);

    function stakeCombined(
        uint256 amount,
        bytes32 planId,
        bool compound,
        bytes32[] calldata stakes,
        bool toWithdrawRewards
    ) external returns (bytes32);

    function emergencyExit(bytes32 stakeId) external returns (uint256 withdrawn, uint256 emergencyLoss);

    function unstake(bytes32 stakeId) external returns (uint256);

    function unstakeTo(bytes32 stakeId, address recipient) external returns (uint256);

    function withdrawRewards(bytes32 stakeId) external returns (uint256);

    function withdrawRewardsTo(bytes32 stakeId, address recipient) external returns (uint256);

    function setPlan(
        uint256 period,
        uint256 apy,
        uint256 emergencyTax,
        uint256 minimalAmount
    ) external returns (bytes32);

    function deactivatePlan(bytes32 plan) external;

    function setCompoundEnabled(bool compoundEnabled) external returns (bool);

    function getCompoundEnabled() external view returns (bool);

    function setCompoundPeriod(uint256 compoundPeriod) external returns (uint256);

    function getCompoundPeriod() external view returns (uint256);

    function setMaxTokensMinted(uint256 maxTokensMinted) external returns (uint256);

    function getMaxTokensMinted() external view returns (uint256);

    function setPricePair(address nativeToken, address stableToken) external returns (address[] memory);

    function getPricePairs() external returns (address[] memory);

    function getPips() external view returns (uint256);

    function getIssuedTokens() external view returns (uint256);

    function getRouter() external view returns (address);

    function getStakes() external view returns (StakeData[] memory stakes);

    function getStakesByAddress(address owner) external view returns (StakeData[] memory);

    function getStakesById(bytes32[] calldata stakeIds) external view returns (Stake[] memory stakes);

    function getDistributedAmount(bytes32 stakeId) external view returns (uint256);

    //Note: Reason to be in contract: Each implementation of a contract defines the type of
    // operations allowing a stake to be combinable
    function getCombinableStakes(
        address owner,
        uint256 amount,
        bytes32 planId
    ) external view returns (bytes32[] memory);

    // function getPlan(bytes32 planId) external view returns (uint256 period, uint256 apy, uint256 emergencyTax);
    function getPlan(bytes32 planId) external view returns (Plan memory);

    function getPlans() external view returns (Plan[] memory plan, bytes32[] memory planIds);

    function expectedRevenue(
        uint256 amount,
        bytes32 planId,
        bool compound,
        uint256 startPeriod,
        uint256 endPeriod
    ) external view returns (uint256);

    function getToken() external view returns (address);
}