// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IAngleGauge {

    //it stakes.
    function deposit(uint256 amount) external;

    //gimme profit
    function claim_rewards() external;

    //gimme principal
    function withdraw(uint256 amount) external;

    //getReward and Withdraw in same go
    function exit() external;

    //basically a sweep in case things get weird
    function recoverERC20(address tokenAddress, address to, uint256 amount) external;

    function balanceOf(address account) external view returns(uint256);

    function claimable_reward(address _user, address _reward_token) external view returns (uint256);

}