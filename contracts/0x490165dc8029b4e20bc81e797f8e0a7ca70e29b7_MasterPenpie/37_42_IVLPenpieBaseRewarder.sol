// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBaseRewardPool.sol";

interface IVLPenpieBaseRewarder is IBaseRewardPool {
    
    function queuePenpie(uint256 _amount, address _user, address _receiver) external returns(bool);
}