// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPendleBooster {
    function poolLength() external view returns (uint256);

    function poolInfo(
        uint256
    ) external view returns (address, address, address, bool);

    function deposit(uint256 _pid, uint256 _amount, bool _stake) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function rewardClaimed(uint256, address, address, uint256) external;

    event Deposited(
        address indexed _user,
        uint256 indexed _poolid,
        uint256 _amount
    );
    event Withdrawn(
        address indexed _user,
        uint256 indexed _poolid,
        uint256 _amount
    );
    event RewardClaimed(
        uint256 _pid,
        address indexed _rewardToken,
        uint256 _amount
    );
    event EarmarkIncentiveSent(
        uint256 _pid,
        address indexed _caller,
        address indexed _token,
        uint256 _amount
    );
    event TreasurySent(uint256 _pid, address indexed _token, uint256 _amount);
    event EqbRewardsSent(
        address indexed _to,
        uint256 _eqbAmount,
        uint256 _xEqbAmount
    );
}