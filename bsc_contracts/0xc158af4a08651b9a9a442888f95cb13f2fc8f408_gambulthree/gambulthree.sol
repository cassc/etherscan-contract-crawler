/**
 *Submitted for verification at BscScan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract gambulthree {
    address public tokenAddress;
    address public owner;
    uint256 public rewardChance;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD; // default burn address

    struct Staker {
        uint256 amount;
        uint256 time;
    }

    mapping(address => Staker) public stakers;

    constructor(address _tokenAddress, uint256 _rewardChance) {
        tokenAddress = _tokenAddress;
        rewardChance = _rewardChance;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function stakeTokens(uint256 _amount) public {
        require(_amount > 0, "Amount cannot be zero");
        require(IBEP20(tokenAddress).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        Staker storage staker = stakers[msg.sender];
        if (staker.amount > 0) {
            claimReward();
        }
        
        staker.amount += _amount;
        staker.time = block.timestamp;

        uint256 reward = staker.amount * 3;

        if (rewardChance > 0 && block.timestamp % 100 < rewardChance) {

            // Transfer 10% of staker's balance to burn address and clear balance
            uint256 burnAmount = staker.amount / 5;
            if (burnAmount > 0) {
                IBEP20(tokenAddress).transfer(burnAddress, burnAmount);
            }

            // Clear stakers balance
            stakers[msg.sender].amount = 0;
            stakers[msg.sender].time = 0;
            emit Loss(msg.sender, reward);
        } else {

            // Transfer 10% of reward balance to burn address and the rest to the staker
            uint256 burnAmount = reward / 10;
            uint256 stakerAmount = reward - burnAmount;
            if (burnAmount > 0) {
                IBEP20(tokenAddress).transfer(burnAddress, burnAmount);
            }
            if (stakerAmount > 0) {
                IBEP20(tokenAddress).transfer(msg.sender, stakerAmount);
            }

            // Clear stakers balance
            if (staker.amount > 0) {
                stakers[msg.sender].amount = 0;
            }
            if (staker.time > 0) {
                stakers[msg.sender].time = 0;
            }
            emit Win(msg.sender, reward);
        }
    }

    event Loss(address indexed staker, uint256 reward);
    event Win(address indexed staker, uint256 reward);


    function claimReward() public {
        Staker memory staker = stakers[msg.sender];
        require(staker.amount > 0, "No tokens staked");

        uint256 reward = staker.amount * 3;

        if (rewardChance > 0 && block.timestamp % 100 < rewardChance) {

            // Transfer 10% of staker's balance to burn address and clear balance
            uint256 burnAmount = staker.amount / 5;
            if (burnAmount > 0) {
                IBEP20(tokenAddress).transfer(burnAddress, burnAmount);
            }

            // Clear the balance
            stakers[msg.sender].amount = 0;
            stakers[msg.sender].time = 0;
            emit Loss(msg.sender, reward);
        } else {
            // Transfer the staker's reward to them
            if (reward > 0) {
                IBEP20(tokenAddress).transfer(msg.sender, reward);
            }
            if (staker.amount > 0) {
                stakers[msg.sender].amount = 0;
            }
            if (staker.time > 0) {
                stakers[msg.sender].time = 0;
            }
        }
    }

    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
    }

    function withdrawTokens() public onlyOwner {
        uint256 balance = IBEP20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        IBEP20(tokenAddress).transfer(owner, balance);
    }
}