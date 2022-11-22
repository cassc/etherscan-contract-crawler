//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function lpToken(uint256 _pid) external view returns (address);

    // lpToken, allocPoint, lastRewardBlock, accCakePerShare
    function poolInfo(uint256 _pid) external view returns (
        address, uint256, uint256, uint256
    );
}