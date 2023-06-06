// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ILQTYStaking {
    /*
    function stake(uint _LQTYamount) external;

    function unstake(uint _LQTYamount) external;

    function increaseF_ETH(uint _ETHFee) external; 

    function increaseF_LUSD(uint _LQTYFee) external;  

    function getPendingETHGain(address _user) external view returns (uint);

    function getPendingLUSDGain(address _user) external view returns (uint);
    */

    function stakes(address) external view returns (uint256);
}