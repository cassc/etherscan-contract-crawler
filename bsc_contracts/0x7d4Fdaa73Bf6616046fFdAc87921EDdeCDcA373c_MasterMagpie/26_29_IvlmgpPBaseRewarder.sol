// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBaseRewardPool.sol";

interface IvlmgpPBaseRewarder is IBaseRewardPool {
    
    function queueMGP(uint256 _amount, address _user, address _receiver) external returns(bool);
}