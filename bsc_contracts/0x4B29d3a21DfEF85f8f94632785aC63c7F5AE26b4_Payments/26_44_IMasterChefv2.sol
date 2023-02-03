pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "../interfaces/IBEP20.sol";

interface IMasterChefv2 {

    struct PoolInfo {
        uint256 accCakePerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
        uint256 totalBoostedShare;
        bool isRegular;
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 boostMultiplier;
    }

    function init(IBEP20 dummyToken) external;

    function poolLength() external view returns (uint256 pools);

    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _isRegular, bool _withUpdate) external;

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function massUpdatePools() external;

    function cakePerBlock(bool _isRegular) external view returns (uint256 amount);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function lptoken(uint256 _pid) external returns(IBEP20);

    function poolInfo(uint256 _pid) external returns (PoolInfo memory);

    function userInfo(uint256 _pid, address _userAddress) external returns (UserInfo memory);

}