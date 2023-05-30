//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.4;

contract PathRewards is Ownable{
    IERC20 public token;

    //total reward tokens will be 150,000,000 given out
    uint public rewardRate = 0;
    uint public rewardsDuration = 365 days;
    uint public startRewardsTime;
    uint public lastUpdateTime;
    uint public lastRewardTimestamp;
    uint public rewardPerTokenStored;

    // last time
    uint private stakedSupply = 0;
    uint private claimedRewards = 0;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => uint) private _balances;

    event Staked(address indexed user, uint amountStaked);
    event Withdrawn(address indexed user, uint amountWithdrawn);
    event RewardsClaimed(address indexed user, uint rewardsClaimed);
    event RewardAmountSet(uint rewardRate, uint duration);

    constructor(address  _tokenAddress, uint _startRewards) {
        token = IERC20(_tokenAddress);
        startRewardsTime = _startRewards;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = rewardTimestamp();
        if (account != address(0)){
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    //function to check if staking rewards have ended
    function rewardTimestamp() internal view returns (uint) {
        if (block.timestamp < lastRewardTimestamp) {
            return block.timestamp;
        }
        else {
            return lastRewardTimestamp;
        }
    }

    //function to check if staking rewards have started
    function startTimestamp() internal view returns (uint) {
        if (startRewardsTime > lastUpdateTime) {
            return startRewardsTime;
        }
        else {
            return lastUpdateTime;
        }
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }


    function totalStaked() public view returns (uint) {
        return stakedSupply;
    }

    function totalClaimed() public view returns (uint) {
        return claimedRewards;
    }

    function rewardPerToken() public view returns (uint) {
        if (stakedSupply == 0 || block.timestamp < startRewardsTime) {
            return 0;
        }
        return rewardPerTokenStored + (
            (rewardRate * (rewardTimestamp()- startTimestamp()) * 1e18 / stakedSupply)
        );
    }

    function earned(address account) public view returns (uint) {
        return (
            _balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18
        ) + rewards[account];
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Must stake > 0 tokens");
        stakedSupply += _amount;
        _balances[msg.sender] += _amount;
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint _amount) public updateReward(msg.sender) {
        require(_amount > 0, "Must withdraw > 0 tokens");
        stakedSupply -= _amount;
        _balances[msg.sender] -= _amount;
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
        emit Withdrawn(msg.sender, _amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            claimedRewards += reward;
            require(token.transfer(msg.sender, reward), "Token transfer failed");
            emit RewardsClaimed(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    //owner only functions

    function setRewardAmount(uint reward, uint _rewardsDuration) onlyOwner external updateReward(address(0)) {
        rewardsDuration = _rewardsDuration;
        rewardRate = reward / rewardsDuration;
        uint balance = token.balanceOf(address(this)) - stakedSupply;

        require(rewardRate <= balance / rewardsDuration, "Contract does not have enough tokens for current reward rate");

        lastUpdateTime = block.timestamp;
        if (block.timestamp < startRewardsTime) {
            lastRewardTimestamp = startRewardsTime + rewardsDuration;
        }
        else {
            lastRewardTimestamp = block.timestamp + rewardsDuration;
        }
        emit RewardAmountSet(rewardRate, _rewardsDuration);
    }
}