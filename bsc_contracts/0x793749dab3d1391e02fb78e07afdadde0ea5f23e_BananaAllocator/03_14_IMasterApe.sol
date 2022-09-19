// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IMasterApe {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function cake() external view returns (address);

    function cakePerBlock() external view returns (uint256);

    function devaddr() external view returns (address);

    function owner() external view returns (address);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function renounceOwnership() external;

    function startBlock() external view returns (uint256);

    function syrup() external view returns (address);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function updateMultiplier(uint256 multiplierNumber) external;

    function poolLength() external view returns (uint256);

    function checkPoolDuplicate(address _lpToken) external view;

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function getPoolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function dev(address _devaddr) external;
}