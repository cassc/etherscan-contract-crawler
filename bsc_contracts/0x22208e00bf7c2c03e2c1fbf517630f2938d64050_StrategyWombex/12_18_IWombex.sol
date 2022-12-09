// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

interface IWombexMasterChef {
    function withdraw(address _lptoken, uint256 _amount, uint256 _minOut, address _recipient) external;
    function booster() external view returns (address);
    function lpTokenToPid(address _lpToken) external view returns (uint256);
}

interface IWombexBooster {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external;
}

interface IWombatMasterChef {
    function deposit(address _token, uint256 _amount, uint256 _minLiquidity, address _to, uint256 _deadline, bool _stake) external;
}

interface IWombexClaim {
    function getReward(address _account, bool _lockCvx) external;
    function claimableRewards(address _account) external view returns (address[] memory, uint256[] memory);
    function operator() external view returns (address);
    function totalSupply() external view returns (uint256);
    function tokenRewards(address _rewardToken) external view returns 
        (address _token, 
        uint256 _periodFinish, 
        uint256 _rewardRate, 
        uint256 _lastUpdateTime, 
        uint256 _rewardPerTokenStored, 
        uint256 _queuedRewards,
        uint256 _currentRewards,
        uint256 _historicalRewards,
        bool _paused);
}

interface IWombexWMXClaim {
    function mintRatio() external view returns (uint256);
    function DENOMINATOR() external view returns (uint256);
    function penaltyShare() external view returns (uint256);
}