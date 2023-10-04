// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FT500StakingWithRewards is Ownable {
    using SafeMath for uint256;

    IERC20 public stakingToken;
    uint256 public totalStaked;
    uint256 public totalRewards;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 duration; // 1, 3, 6, or 12 months represented as seconds
        uint256 tier; // Tier 1, 2, 3, 4, or 5
        uint256 reward;
        uint256 rewardDebt;
    }

    // Mapping of user addresses to their staking positions
    mapping(address => Stake) public stakes;

    uint256[5][] public rewardPercentages = [
        [200, 400, 800, 1600], // Tier 1
        [300, 600, 1200, 1800], // Tier 2
        [400, 800, 1600, 2000], // Tier 3
        [500, 1000, 2000, 2500], // Tier 4
        [800, 1600, 2400, 3200] // Tier 5
    ];

    uint256 internal accRewardPerToken;

    // ==============
    //   CONSTANTS
    // ==============
    uint256 internal constant PRECISION = 1e18;


    // ==============
    //    EVENTS
    // ==============
    event Deposit(address indexed user, uint256 indexed stakedAmount);

    event Withdraw(address indexed user, uint256 indexed withdrawAmount);

    event Harvest(address indexed user, uint256 indexed harvestAmount);

    event RewardsAdded(uint256 amount);

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    // Stake tokens with a specified lockup period and tier
    function stake(uint256 amount, uint256 duration) external {
        
        require(duration == 1 || duration == 3 || duration == 6 || duration == 12, "Invalid duration");

        // Transfer tokens to the contract
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        //check if user already has stake
        if(stakes[msg.sender].amount > 0){
            totalStaked = totalStaked.sub(stakes[msg.sender].amount);
            totalRewards = totalRewards.sub(stakes[msg.sender].reward);
            amount += stakes[msg.sender].amount;
        } 

        
        uint8 tier;
        if(amount < 100_000 * 1e18){
            tier = 1;    
        }else if(amount >= 100_000 * 1e18 && amount < 250_000 * 1e18){
            tier = 2;
        }else if(amount >= 250_000 * 1e18 && amount < 500_000 * 1e18){
            tier = 3;
        }else if(amount >= 500_000 * 1e18 && amount < 1_000_000 * 1e18){
            tier = 4;
        }else if(amount >= 1_000_000 * 1e18){
            tier = 5;
        }

        require(tier >= 1 && tier <= 5, "Invalid tier");

        uint8 rewardPecentageIndex;

        if(duration == 1){
            rewardPecentageIndex = 1;
        }else if(duration == 3){
            rewardPecentageIndex = 2;
        }else if(duration == 6){
            rewardPecentageIndex = 3;
        }else if(duration == 12){
            rewardPecentageIndex = 4;
        }


        uint256 rewardPercentage = rewardPercentages[tier - 1][rewardPecentageIndex - 1];

        // use updated amount to calculate reward
        uint256 reward = amount.mul(rewardPercentage).div(10_000);

        // Update user's staking position
        stakes[msg.sender] = Stake(amount, block.timestamp, duration * 30 days, tier, reward, 0);
        _updateUserDebt(msg.sender, amount);

        // Update total staked amount
        totalStaked = totalStaked.add(amount);
        // Update total reward
        totalRewards = totalRewards.add(reward);
    }

    // Withdraw staked tokens and rewards
    function withdraw() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No staking position");

        harvest();

        uint256 stakedAmount = userStake.amount;
        uint256 rewards = stakes[msg.sender].reward;

        // Calculate the time elapsed since the start of the stake
        uint256 elapsedTime = block.timestamp.sub(userStake.startTime);

        //else take earlyWithdrawal fees

        // Update total staked amount
        totalStaked = totalStaked.sub(stakedAmount);
        //  update total rewards
        totalRewards = totalRewards.sub(rewards);

        if(elapsedTime >= userStake.duration){
            delete stakes[msg.sender];
            //if stake time is elapsed, send rewards and send back staked funds
            require(stakingToken.transfer(msg.sender, rewards+stakedAmount), "Transfer failed");

        }else{
            delete stakes[msg.sender];

            // Calculate the early withdrawal fee (10% of the staked amount)
            uint256 earlyWithdrawalFee = (stakedAmount.mul(10)).div(100);
            // Adjust the staked amount after applying the fee
            stakedAmount = stakedAmount.sub(earlyWithdrawalFee);
            require(stakingToken.transfer(msg.sender, stakedAmount), "Transfer failed");
        }
    }
    //claim rewards
    function claimRewards() external{
        // ensure user has stake
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No staking position");

        uint256 rewards = userStake.reward;

        // Calculate the time elapsed since the start of the stake
        uint256 elapsedTime = block.timestamp.sub(userStake.startTime);
        require(elapsedTime >= userStake.duration, "Staking duration not completed");
        
        
        totalRewards = totalRewards.sub(rewards);
        stakes[msg.sender].reward = 0;
        require(stakingToken.transfer(msg.sender, rewards), "Transfer failed");
    }

    function recommit() external {
        // ensure user has stake
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No staking position");

        uint256 stakedAmount = userStake.amount;
        uint256 rewards = userStake.reward;

        // Calculate the time elapsed since the start of the stake
        uint256 elapsedTime = block.timestamp.sub(userStake.startTime);
        require(elapsedTime >= userStake.duration, "Staking duration not completed");
        
        totalStaked = totalStaked.sub(stakedAmount);
        totalRewards = totalRewards.sub(rewards);

        //update staked amount
        stakedAmount = stakedAmount.add(rewards);
        //update rewards based on increased amount
        uint8 rewardPecentageIndex;

        //recalculate reward and tier  
        uint256 duration = userStake.duration / 30 days;

        if(duration == 1){
            rewardPecentageIndex = 1;
        }else if(duration == 3){
            rewardPecentageIndex = 2;
        }else if(duration == 6){
            rewardPecentageIndex = 3;
        }else if(duration == 12){
            rewardPecentageIndex = 4;
        }

        uint8 tier;

        if(stakedAmount < 100_000 * 1e18){
            tier = 1;    
        }else if(stakedAmount >= 100_000 * 1e18 && stakedAmount < 250_000 * 1e18){
            tier = 2;
        }else if(stakedAmount >= 250_000 * 1e18 && stakedAmount < 500_000 * 1e18){
            tier = 3;
        }else if(stakedAmount >= 500_000 * 1e18 && stakedAmount < 1_000_000 * 1e18){
            tier = 4;
        }else if(stakedAmount >= 1_000_000 * 1e18){
            tier = 5;
        }

        require(tier >= 1 && tier <= 5, "Invalid tier");
        uint256 rewardPercentage = rewardPercentages[tier - 1][rewardPecentageIndex - 1];

        // use updated amount to calculate reward
        uint256 newReward = stakedAmount.mul(rewardPercentage).div(10_000);

        // Update total staked amount
        totalStaked = totalStaked.add(stakedAmount);
        // Update total reward
        totalRewards = totalRewards.add(newReward);

        stakes[msg.sender].amount = stakedAmount;
        stakes[msg.sender].amount = stakedAmount;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].duration = duration * 30 days;      
        stakes[msg.sender].tier = tier;
        stakes[msg.sender].reward = newReward;

        _updateUserDebt(msg.sender, stakedAmount);

    }

    // Owner-only function to withdraw any remaining tokens from the contract
    function withdrawTokens(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) > 0, "No tokens to withdraw");
        require(token.transfer(owner(), amount), "Transfer failed");
    }

    // Owner-only function to change the staking token
    function changeStakingToken(address newToken) external onlyOwner {
        stakingToken = IERC20(newToken);
    }

    // Check if a wallet has staked
    function hasStake(address user) external view returns (bool) {
        return stakes[user].amount > 0;
    }
    
    function withdrawStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {}
    // =============
    //    ADMIN
    // =============

    // Distribute rewards
    function distributeRewards(uint amount) external payable {
        require(msg.value == amount, "Enter correct amount");
        
        if (totalStaked > 0) accRewardPerToken += (amount * PRECISION) / totalStaked;

        emit RewardsAdded(amount);
    }

    // Harvest rewards
    function harvest() public {
        Stake memory _stake = stakes[msg.sender];

        uint pendingRewards = _pendingHarvestRewards(_stake);

        stakes[msg.sender].rewardDebt =
            (_stake.amount * accRewardPerToken) /
            PRECISION;

        (bool success, ) = msg.sender.call{value: pendingRewards}("");
        require(success);

        emit Harvest(msg.sender, pendingRewards);
    }

    // Rewards to be harvested
    function _pendingHarvestRewards(Stake memory _stake) internal view returns (uint) {
        return
            (_stake.amount * accRewardPerToken) / PRECISION - _stake.rewardDebt;
    }

    function _updateUserDebt(address user, uint256 newAmount) internal {
        stakes[user].rewardDebt = (newAmount * accRewardPerToken) / PRECISION;
    }

    function getPendingHarvestRewards() external view returns (uint){
        return _pendingHarvestRewards(stakes[msg.sender]);
    }
}