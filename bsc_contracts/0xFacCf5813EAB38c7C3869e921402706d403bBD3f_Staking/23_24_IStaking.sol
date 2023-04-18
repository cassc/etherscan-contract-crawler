// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "../data/StructData.sol";

interface IStaking {
    event Staked(
        uint256 id,
        address indexed staker,
        uint256 indexed nftID,
        uint256 unlockTime,
        uint16 apy
    );
    event Unstaked(uint256 id, address indexed staker, uint256 indexed nftID);
    event Claimed(uint256 id, address indexed staker, uint256 claimAmount);

    event PayCommission(address staker, address refAccount, uint256 commissionAmount);

    event ErrorLog(bytes message);

    function setTimeOpenStaking(uint256 _timeOpening) external;

    function initStakeApy() external;

    function initComissionConditionUsd() external;

    function initCommissionLevel() external;

    function getStakeApyForTier(uint32 _nftTier) external returns (uint16);

    function setStakeApyForTier(uint32 _nftTier, uint16 _apy) external;

    function getComissionCondition(uint8 _level) external returns (uint32);

    function setComissionCondition(uint8 _level, uint32 _conditionInUsd) external;

    function getCommissionPercent(uint8 _level) external returns (uint16);

    function setCommissionPercent(uint8 _level, uint16 _percent) external;

    function getTotalCrewInvesment(address _wallet) external returns (uint256);

    function getTeamStakingValue(address _wallet) external returns (uint256);

    function getStakingCommissionEarned(address _wallet) external returns (uint256);

    function forceUpdateTotalCrewInvesment(address _user, uint256 _value) external;

    function forceUpdateTeamStakingValue(address _user, uint256 _value) external;

    function forceUpdateStakingCommissionEarned(address _user, uint256 _value) external;

    function stake(
        uint256[] memory _nftIds,
        uint256 _stakingPeriod,
        uint256 _refCode,
        bytes memory _data
    ) external;

    function stakeOnlyAdmin(
        uint256[] memory _nftIds,
        uint256 _stakingPeriod,
        address _user,
        uint256 _fromTimestamp,
        uint256 _totalClaimedWithDecimal
    ) external;

    function unstake(uint256 _stakeId, bytes memory data) external;

    function claim(uint256 _stakeId) external;

    function claimAll(uint256[] memory _stakeIds) external;

    function getDetailOfStake(
        address _staker,
        uint256 _stakeId
    ) external view returns (StructData.StakedNFT memory);

    function calculateRewardInUsd(
        uint256 _totalValueStake,
        uint256 _stakingPeriod,
        uint16 _apy
    ) external pure returns (uint256);

    function possibleUnstake(address _user, uint256 _stakeId) external view returns (bool);

    function claimableForStakeInUsdWithDecimal(
        address _staker,
        uint256 _stakeId
    ) external view returns (uint256);

    function rewardUnstakeInTokenWithDecimal(
        address _staker,
        uint256 _stakeId
    ) external view returns (uint256);

    function getTotalStakeAmountUSD(address _staker) external view returns (uint256);

    function possibleForCommission(address _staker, uint8 _level) external view returns (bool);

    function getEffectDecimalForCurrency() external view returns (uint256);

    function depositToken(uint256 _amount) external payable;

    function withdrawTokenEmergency(uint256 _amount) external;

    function withdrawCurrencyEmergency(address _currency, uint256 _amount) external;

    function tranferNftEmergency(address _receiver, uint256 _nftId) external;

    function tranferMultiNftsEmergency(
        address[] memory _receivers,
        uint256[] memory _nftIds
    ) external;

    function estimateValueUsdForListNft(uint256[] memory _nftIds) external view returns (uint256);

    function setOracleAddress(address _oracleAddress) external;

    function updateStakeApyEmergency(
        address _user,
        uint256[] memory _stakeIds,
        uint16[] memory _newApys
    ) external;

    function removeStakeEmergency(address _user, uint256[] memory _stakeIds) external;
}