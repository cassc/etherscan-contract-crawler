// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IStakePool {
    enum RewardType {
        PercentRatio,
        FixedRatio,
        NoRatio,
        NoReward
    }
    enum StakeStatus {
        Alive,
        Cancelled
    }
    struct StakeModel {
        RewardType rewardType;
        uint256 rewardRatio;
        uint256 startDateTime;
        uint256 endDateTime;
        uint256 minAmountToStake;
        bool transferrable;
        uint256 minPeriodToStake;
        bool canClaimAnyTime;
        uint256 claimDateTime;   
        string extraData; 
    }
    function status() external view returns (StakeStatus);
    function stakers(uint256) external view returns (address);
    function stakerIndex(address) external view returns (uint256);
    function depositAmount() external view returns (uint256);
    function totalRewardsDistributed() external view returns (uint256);
    function lastClaimTimes(address) external view returns (uint256);
    function lastDistributeTime() external view returns (uint256);
    function stakeModel() external view returns (
        RewardType rewardType,
        uint256 rewardRatio,
        uint256 startDateTime,
        uint256 endDateTime,
        uint256 minAmountToStake,
        bool transferrable,
        uint256 minPeriodToStake,
        bool canClaimAnyTime,
        uint256 claimDateTime,
        string memory extraData
    );
    function rewardToken() external view returns (address);
    function stakeToken() external view returns (address);
    function stakeOwner() external view returns (address);
    function stakeDateTime(address) external view returns (uint256);
    function updateExtraData(string calldata) external;
    // function updatePeriod(uint256 _startDateTime, uint256 _endDateTime) external;
    function updateAmountLimit(uint256 _minAmountToStake) external;
    function updateTransferrable(bool _transferrable, uint256 _minPeriodToStake) external;
    // function updateClaimTime(bool _canClaimAnyTime, uint256 _claimDateTime) external;
    
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function withdrawnRewardOf(address owner_)
        external
        view
        returns (uint256);
    function withdrawableRewardOf(address owner_)
        external
        view
        returns (uint256);
    function accumulativeRewardOf(address owner_)
        external
        view
        returns (uint256);
    function getAccount(address _account)
        external
        view
        returns (
            address account,
            int256 index,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            uint256 lastClaimTime
        );
    function getAccountAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            uint256,           
            uint256,
            uint256
        );
    function claim() external;
    function getNumberOfStakers() external view returns (uint256);
    function depositRewards(uint256 amount) external;
    function distributeRewards() external returns (uint256);
    function initialize(
        string memory name_,
        string memory symbol_,
        StakeModel memory _stakeModel,
        address _rewardToken,
        address _stakeToken,
        address _stakeOwner,
        uint256 hardCap
    ) external;
    function cancel() external;
}