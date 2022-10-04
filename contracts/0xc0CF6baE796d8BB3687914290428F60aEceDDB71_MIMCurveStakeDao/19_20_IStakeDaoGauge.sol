//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakeDaoGauge is IERC20{
    function claimable_reward(address _user, address _reward_token) external view returns (uint256);
    function claim_rewards() external;
    function withdraw(uint256 _value, address _addr, bool _claim_rewards) external;
}