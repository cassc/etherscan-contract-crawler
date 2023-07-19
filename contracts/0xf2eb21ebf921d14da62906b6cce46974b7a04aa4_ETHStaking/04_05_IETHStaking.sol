// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IETHStaking {
    /*********** STRUCT ***********/
    struct UserInfo {
        uint256 amount;
        uint256 rewardPaid;
        uint256 lastUpdated;
    }

    /*********** ENUM ***********/
    enum ActionType {
        Stake,
        Unstake
    }

    /*********** EVENTS ***********/
    event Staked(address indexed user, uint256 amount, uint256 stakeNum);
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 reward,
        uint256 stakeNum
    );
    event OwnerWithdrawFunds(address indexed beneficiary, uint256 amount);
    event ETHTransferred(address indexed beneficiary, uint256 amount);
    event APYChanged(uint256 apy, uint256 correctionFactor);

    /*********** GETTERS ***********/
    function totalValueLocked() external view returns (uint256);

    function apy() external view returns (uint256);

    function correctionFactor() external view returns (uint256);

    function userInfo(address, uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function stakeNums(address) external view returns (uint256);

    function balanceOf(address _account, uint256 _stakeNum)
        external
        view
        returns (uint256);

    function stakeExists(address _beneficiary, uint256 _stakeNum)
        external
        view
        returns (bool);

    function calculateReward(address _beneficiary, uint256 _stakeNum)
        external
        view
        returns (uint256);

    function contractBalance() external view returns (uint256);

    /*********** ACTIONS ***********/
    function stake() external payable;

    function unstake(uint256 _stakeNum) external;

    function changeAPY(uint256 _apy, uint256 _correctionFactor) external;

    function withdrawContractFunds(uint256 _amount) external;

    function destructContract() external;
}