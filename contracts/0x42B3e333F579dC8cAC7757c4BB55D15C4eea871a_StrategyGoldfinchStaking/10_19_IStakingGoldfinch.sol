// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IStakingGoldfinch {

    enum StakedPositionType  {
        Fidu,
        CurveLP
    }

    function addToStake(uint256 tokenId, uint256 amount) external;

    function balanceOf(address _owner) external view returns (uint256);

    function optimisticClaimable(uint256 tokenId) external view returns (uint256 rewards);

    function getReward(uint256 tokenId) external;

    function stake(uint256 _amount, StakedPositionType _positionType) external returns (uint256);

    function stakedBalanceOf(uint256 tokenId) external view returns (uint256);

    function unstake(uint256 tokenId, uint256 amount) external;

}