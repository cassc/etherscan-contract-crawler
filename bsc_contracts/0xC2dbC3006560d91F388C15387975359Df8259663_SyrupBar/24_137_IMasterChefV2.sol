// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

interface IMasterChefV2 {

    function userInfo(address user) external returns (uint, uint);

    function pendingReward(address _user) external view returns (uint256);

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

}