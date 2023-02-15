// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMPStaking {

    function emergencyWithdrawBNB (address _to) external;

    function emergencyWithdrawToken (
        address _tokenAddress,
        address _to
    ) external;
    
    function addToken (address _token) external;

    function removeToken (address _token) external;

    function addTokens (address[] memory _tokens) external;

    function stakeToken (
        address _token,
        uint256 _stakeAmount
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