// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
interface INFT {
    function balanceOf(address account) external view returns (uint256);
}

contract EvaultStaking {
    address public tokenAddress;
    address public nftAddress;
    uint256 public rewardRate = 120; // 20% additional rewards for users with NFTs
    uint256 public stakeDuration;
    uint256 public totalRewards;
    uint256 public totalStaked;
    
    mapping(address => Stake) public stakes;
    mapping(address => uint256) public rewards;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event EmergencyWithdrawn(address indexed user, uint256 amount, uint256 fee);
    
    
    struct Stake {
        uint256 amount;
        uint256 startTimestamp;
    }
    
    constructor(address _tokenAddress, address _nftAddress, uint256 _stakeDurationInMinutes) {
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
        stakeDuration = _stakeDurationInMinutes * 1 minutes;
    }
    
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount, "Must approve token transfer first");
        require(block.timestamp < stakes[msg.sender].startTimestamp + stakeDuration, "Staking period has ended");
        
        if (INFT(nftAddress).balanceOf(msg.sender) > 0) {
            // User has NFT, give additional reward
            rewards[msg.sender] += calculateReward(amount, rewardRate);
        } else {
            rewards[msg.sender] += calculateReward(amount, 100); // No additional reward
        }
        
        stakes[msg.sender] = Stake(stakes[msg.sender].amount + amount, block.timestamp);
        totalStaked += amount;
        
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        emit Staked(msg.sender, amount);
    }
    
    function withdraw() external {
        require(stakes[msg.sender].amount > 0, "No stake to withdraw");
        require(block.timestamp >= stakes[msg.sender].startTimestamp + stakeDuration, "Staking period has not ended");
        
        uint256 reward = rewards[msg.sender];
        uint256 amount = stakes[msg.sender].amount;
        totalRewards += reward;
        totalStaked -= amount;
        
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Contract has insufficient token balance");
          require(IERC20(tokenAddress).transfer(msg.sender, amount + reward), "Token transfer failed");
    
    stakes[msg.sender] = Stake(0, 0);
    rewards[msg.sender] = 0;
    
    emit Withdrawn(msg.sender, amount);
    emit RewardPaid(msg.sender, reward);
}

function emergencyWithdrawal() external {
    require(stakes[msg.sender].amount > 0, "No stake to withdraw");
    uint256 amount = stakes[msg.sender].amount;
    uint256 fee = amount / 10; // Calculate 10% fee
    uint256 remainingAmount = amount - fee;
    totalStaked -= amount;
    stakes[msg.sender] = Stake(0, 0);
    
    require(IERC20(tokenAddress).balanceOf(address(this)) >= remainingAmount, "Contract has insufficient token balance");
    require(IERC20(tokenAddress).transfer(msg.sender, remainingAmount), "Token transfer failed");
    
    if (fee > 0) {
        require(IERC20(tokenAddress).transfer(owner(), fee), "Token transfer failed");
        emit EmergencyWithdrawn(msg.sender, remainingAmount, fee);
    } else {
        emit EmergencyWithdrawn(msg.sender, remainingAmount, 0);
    }
}

function calculateReward(uint256 amount, uint256 rate) internal pure returns (uint256) {
    return amount * rate / 10000;
}

function setRewardRate(uint256 rate) external {
    rewardRate = rate;
}

function setStakeDuration(uint256 durationInMinutes) external {
    stakeDuration = durationInMinutes * 1 minutes;
}

function owner() internal view returns (address) {
    return msg.sender;
}

function getTotalStaked() external view returns (uint256) {
    return totalStaked;
}

function getTotalRewards() external view returns (uint256) {
    return totalRewards;
}
}