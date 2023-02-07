// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMasterChefV3 {

    function userInfo(uint _pid, address user) external returns (uint, uint);

    function pendingReward(address _user) external view returns (uint256);

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function poolInfo(uint256 _pid) external returns (IERC20, uint, uint, uint);

}