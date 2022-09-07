// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

struct PancakePoolInfo {
        uint256 accCakePerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
        uint256 totalBoostedShare;
        bool isRegular;
}

interface IPancakeswapFarm {
    
    function lpToken(uint256 _pid) external view returns (address);
    function poolInfo(uint256 _pid) external view returns (PancakePoolInfo memory);
    function poolLength() external view returns (uint256);
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;
}