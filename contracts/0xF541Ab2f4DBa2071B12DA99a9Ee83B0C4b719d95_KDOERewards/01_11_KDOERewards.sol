// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./NFTWrapper.sol";
import "./TokenWrapper.sol";

contract KDOERewards is TokenWrapper, NFTWrapper, Ownable {
    IERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardPerNFTStored;
    bool public multiNftReward;
    uint256 public maxNftRewardBalance;
	
    struct UserRewards {
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }
	
    mapping(address => UserRewards) public userRewards;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
	event UpdategKDOEAddress(IGKDOE indexed gKDOE);
	event UpdategNFTRewardStatus(bool status);
	event rewardWithdraw(address indexed user, uint256 reward);

    constructor(IERC20 _rewardToken, IERC20 _stakedToken, IERC721 _stakedNFT) {
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
        stakedNFT = _stakedNFT;
    }
	
    modifier updateReward(address account) {
        uint256 _rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewardPerTokenStored = _rewardPerTokenStored;
        userRewards[account].rewards = earned(account);
        userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
        _;
    }
	
    function setgKDOE(IGKDOE _gKDOE) external onlyOwner {
        gKDOE = _gKDOE;
		emit UpdategKDOEAddress(gKDOE);
    }
	
    function setMultiNftReward(bool _multiNftReward) external onlyOwner {
        multiNftReward = _multiNftReward;
		emit UpdategNFTRewardStatus(_multiNftReward);
    }
	
    function lastTimeRewardApplicable() public view returns (uint256) {
        uint256 blockTimestamp = uint256(block.timestamp);
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }
	
    function rewardPerToken() public view returns (uint256) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0) {
            return rewardPerTokenStored;
        }
        unchecked {
            uint256 rewardDuration = lastTimeRewardApplicable() - lastUpdateTime;
            return uint256(rewardPerTokenStored + (rewardDuration * rewardRate * 1e18) / totalStakedSupply);
        }
    }
	
	
    function nftReward(uint256 nftBalance, uint256 newAmount) public view returns (uint256) {
        if (multiNftReward) 
		{
            uint256 nftRewards = uint256(newAmount * (nftBalance * rewardPerNFTStored) / 100);
            return nftRewards;
        } 
		else 
		{
            uint256 nftRewards = uint256(newAmount * rewardPerNFTStored / 100);
            return nftRewards;
        }
    }
	
    function earned(address account) public view returns (uint256) {
        unchecked {
            uint256 newAmount = uint256((balanceOf(account) * (rewardPerToken() - userRewards[account].userRewardPerTokenPaid)) / 1e18);
            uint256 amount = uint256(newAmount + userRewards[account].rewards);
			uint256 nftBalance = uint256(balanceOfNFT(account));
            if (nftBalance > 0) {
                amount += nftReward(nftBalance, newAmount);
            }
            return amount;
        }
    }
	
    function stake(uint256 amount) external payable updateReward(msg.sender){
        super.stakeFor(msg.sender, amount);
    }
	
    function stakeNFT(uint256 tokenId) public payable updateReward(msg.sender) {
	    require(maxNftRewardBalance > balanceOfNFT(msg.sender), "Max NFT already stake");
		if(!multiNftReward)
		{
		    require(balanceOfNFT(msg.sender) == 0, "Max NFT already stake");
		}
        super.stakeNFT(msg.sender, tokenId);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        super.withdraw(msg.sender, amount);
    }
	
    function withdrawForgKDOE(uint256 amount) public updateReward(msg.sender) {
        super.withdrawForgKDOE(msg.sender, amount);
    }
	
	function stakeForgKDOE(uint256 amount) public updateReward(msg.sender) {
        super.stakeForgKDOE(msg.sender, amount);
    }

    function unstakeNFT(uint256 tokenId) public payable updateReward(msg.sender) {
        super.unstakeNFT(msg.sender, tokenId);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        require(reward > 0, "No rewards to withdraw");
        userRewards[msg.sender].rewards = 0;
        require(
            rewardToken.transfer(msg.sender, reward),
            "reward transfer failed"
        );
        emit RewardPaid(msg.sender, reward);
    }
	
    function setRewardParams( uint256 reward, uint256 duration, uint256 nftreward, uint256 maxNftBalance) external onlyOwner {
        unchecked 
		{
            require(reward > 0, "Reward can't be zero");
            rewardPerTokenStored = rewardPerToken();
            uint256 blockTimestamp = uint256(block.timestamp);
            uint256 maxRewardSupply = rewardToken.balanceOf(address(this));
            if (rewardToken == stakedToken) maxRewardSupply -= totalSupply;
            uint256 leftover = 0;
            if (blockTimestamp >= periodFinish) 
			{
                rewardRate = reward / duration;
            } 
			else 
			{
                uint256 remaining = periodFinish - blockTimestamp;
                leftover = remaining * rewardRate;
                rewardRate = (reward + leftover) / duration;
            }
            rewardPerNFTStored = nftreward;
            maxNftRewardBalance = maxNftBalance;
            require(reward + leftover <= maxRewardSupply, "not enough tokens");
            lastUpdateTime = blockTimestamp;
            periodFinish = blockTimestamp + duration;
            emit RewardAdded(reward);
        }
    }
	
    function withdrawReward() external onlyOwner {
        uint256 rewardSupply = rewardToken.balanceOf(address(this));
        //ensure funds staked by users can't be transferred out
        if (rewardToken == stakedToken) rewardSupply -= totalSupply;
        require(rewardToken.transfer(msg.sender, rewardSupply), "Error in transfer reward");
        rewardRate = 0;
        periodFinish = uint256(block.timestamp);
		
		emit rewardWithdraw(msg.sender, rewardSupply);
    }
}