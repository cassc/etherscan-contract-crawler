// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMPStaking {

    event Staked(
        address indexed from,
        uint256 amount,
        address token
    );
    event UnStaked(
        address indexed from,
        uint256 amount,
        address token
    );

    function emergencyWithdrawBNB (address _to) external;

    function emergencyWithdrawToken (
        address _tokenAddress,
        address _to
    ) external;

    function addStakingToken (address _token) external;

    function removeStakingToken (address _token) external;

    function addRewardToken (address _token) external;

    function removeRewardToken (address _token) external;
    
    function batchStakeTokens (
        address[] memory _tokens, 
        uint256[] memory _stakeAmounts
    ) external;

    function unStakeWithRewards (
        address _token,
        uint256 _unStakingPercent
    ) external returns (bool);

    function withdrawRewards (
        address _token,
        uint256 _withdrawPercent
    ) external returns (bool);

    function compoundRewards (
        address _token,
        uint256 _compoundPercent
    ) external returns (bool);

    function getStakedTokenAmount (
        address _wallet,
        address _token
    ) external view returns (uint256);

}