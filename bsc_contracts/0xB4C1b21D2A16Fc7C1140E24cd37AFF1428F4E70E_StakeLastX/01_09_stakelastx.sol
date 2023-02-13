// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface ISupply{
  function safeTokenTransfer(address to, uint256 amount) external;
}

contract StakeLastX is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
	
	address public NMSLP;
	address public supplyContract;
	
	struct UserInfo {
	  uint256 amount; 
	  uint256 startDay;
	  uint256 rewardDebtDay;
    }
	
	uint256 public totalStaked;
	uint256 public numUsers;
	uint256 public rewardPercent;
	uint256 public decayPercent;
	uint256 public rewardPoolBalance;
	uint256 public nextRewardTime;
	uint256 public currentDay;
	uint256 public precisionFactor;
	
	address[] public users;
	
	mapping(uint256 => uint256)public accTokenPerShare;
	mapping(address => UserInfo) public mapUserInfo;
	mapping(address => bool) public userExistence;
	
    event MigrateTokens(address tokenRecovered, address receiver, uint256 amount);
    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
	event NewUnlockFeeUpdated(uint256 newFee);
	event PoolUpdated(uint256 amount);	
	event RewardPercentUpdate(uint256 newPercent);
	event DecayPercentUpdate(uint256 newPercent);
	event RewardPoolBalanceUpdate(uint256 newAmount);
	
    constructor () {
	   precisionFactor = 1 * 10**18;
	   rewardPoolBalance = 100 * 10**18; 
	   rewardPercent = 200;
	   decayPercent = 100;
	   nextRewardTime = 1676237400;
	   NMSLP = address(0x2CBceE506304b579149749758BBF877B4b40E6d2);
	   supplyContract = address(0xa745c77f15DB6490f8185e9Affceb78Da780837A);
    }
	
	function clcDay() public view returns (uint256) {
       return (block.timestamp - (nextRewardTime - 1 hours)) / 1 hours;
    }
	
	function ownerUpdate(address[] calldata user) external onlyOwner {
        for (uint i = 0; i < user.length; i++) {
            _deposit(user[i], 0);
        }
    }
	
	function deposit(uint256 amount) external nonReentrant whenNotPaused {
        _deposit(msg.sender, amount);
    }
	
	function _deposit(address user, uint256 amount) internal {
		require(IERC20(NMSLP).balanceOf(user) >= amount, "balance not available for staking");
		require(amount > 0, "Amount can't be zero");
		updatePool();
		
	    (uint256 pending, uint256 newAmount) = pendingReward(user);
		if (pending > 0) {
		   ISupply(supplyContract).safeTokenTransfer(address(user), pending);
		}
		
		IERC20(NMSLP).safeTransferFrom(address(user), 0x7b3d7870ecA6C38fF9ae72b0ecae54f2d32B59cC, amount);
		
		mapUserInfo[user].amount = newAmount + amount;
		mapUserInfo[user].startDay = currentDay;
		mapUserInfo[user].rewardDebtDay = currentDay;
		
		if(!userExistence[user]) {
           userExistence[user] = true;
           users.push(user);
           numUsers++;
        }
		totalStaked += amount;
        emit Deposit(msg.sender, amount);
    }
	
	function withdrawReward() external nonReentrant whenNotPaused{
		updatePool();
		if(mapUserInfo[msg.sender].amount > 0) 
		{
		    (uint256 pending, uint256 newAmount) = pendingReward(msg.sender);
			if (pending > 0)  
			{
			   ISupply(supplyContract).safeTokenTransfer(address(msg.sender), pending);
			}
			mapUserInfo[msg.sender].rewardDebtDay = currentDay;
			mapUserInfo[msg.sender].amount = newAmount;
			emit Withdraw(msg.sender, pending);
        } 
    }
	
	function emergencyWithdraw() external nonReentrant{
       updatePool();
	   if(mapUserInfo[msg.sender].amount > 0) 
	   {
		    (uint256 pending, uint256 newAmount) = pendingReward(msg.sender);
			if(pending > 0)  {
			   ISupply(supplyContract).safeTokenTransfer(address(msg.sender), pending);
			}
			mapUserInfo[msg.sender].rewardDebtDay = currentDay;
			mapUserInfo[msg.sender].amount = newAmount;
			
		   totalStaked -= mapUserInfo[msg.sender].amount;
		   IERC20(NMSLP).safeTransfer(address(msg.sender), mapUserInfo[msg.sender].amount);
		   
		   mapUserInfo[msg.sender].rewardDebtDay = 0;
		   mapUserInfo[msg.sender].amount = 0;
		   mapUserInfo[msg.sender].startDay = 0;
	   }
    }
	
	function updatePool() public {
		if(clcDay() > 0)
		{
			uint256 numdays = clcDay(); 
			uint256 tAmount;
			for (uint256 i = 0; i < numdays; i++) 
			{
			    currentDay++;
				if(totalStaked > 0 && rewardPoolBalance > 0)
				{
				    uint256 amount = rewardPoolBalance * rewardPercent / 10000;
					tAmount += amount;
					accTokenPerShare[currentDay] = amount * precisionFactor / totalStaked;
					
					totalStaked -= totalStaked * decayPercent / 10000;
					rewardPoolBalance -= rewardPoolBalance * rewardPercent / 10000;
				}
				else
				{
				   accTokenPerShare[currentDay] = 0;
				}
			}
			nextRewardTime += numdays * 1 hours;
			emit PoolUpdated(tAmount);
		}
    }
	
	function pendingReward(address user) public view returns (uint256 pending, uint256 newAmount) {
		if(mapUserInfo[user].amount > 0) 
		{   
		    if(currentDay > mapUserInfo[user].rewardDebtDay)
			{
			    newAmount = mapUserInfo[user].amount;
				uint256 numdays = currentDay - mapUserInfo[user].rewardDebtDay;
				uint256 startday = mapUserInfo[user].rewardDebtDay + 1;
				for (uint256 i = 0; i < numdays; i++) 
				{
				    if(accTokenPerShare[startday] > 0 && newAmount > 0) {
					   pending += newAmount * accTokenPerShare[startday] / precisionFactor;
					}
					if(newAmount > 0) {
					   newAmount -= newAmount * decayPercent / 10000;
					}
					startday++;
				}
				return (pending, newAmount);
			}
			else
			{
			    return (0, mapUserInfo[user].amount);
			}
        } 
		else 
		{
		   return (0, 0);
		}
    }
	
	function setTokenRewardPercent(uint percent) external onlyOwner {
       require(10000 >= percent, "Percent can't be more than `100`");
	   
	   updatePool();
	   rewardPercent = percent;
	   emit RewardPercentUpdate(percent);
    }
	
    function setDecayPercent(uint percent) external onlyOwner {
       require(10000 >= percent, "Percent can't be more than `100`");
	   
	   updatePool();
       decayPercent = percent;
	   emit DecayPercentUpdate(percent);
    }
	
	function setTokenRewardAmount(uint amount) external onlyOwner {
	   require(amount > 0, "Amount can't be zero");
	   
       updatePool();
       rewardPoolBalance += amount;
	   emit RewardPoolBalanceUpdate(amount);
    }
	
	function getUserDetails(uint startIndex, uint endIndex) external view returns (UserInfo[] memory) {
        if (endIndex == 0) {
            endIndex = numUsers;
        }
        UserInfo[] memory userInfos = new UserInfo[](endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            userInfos[i] = mapUserInfo[users[i]];
        }
        return userInfos;
    }
	
	function migrateTokens(address tokenAddress, address receiver, uint256 tokenAmount) external onlyOwner{
       require(tokenAddress != address(0), "Zero address");
	   require(receiver != address(0), "Zero address");
	   require(IERC20(tokenAddress).balanceOf(address(this)) >= tokenAmount, "Insufficient balance on contract");
	   
	   IERC20(tokenAddress).safeTransfer(address(receiver), tokenAmount);
       emit MigrateTokens(tokenAddress, receiver, tokenAmount);
    }
	
	
	
	function pause() public onlyOwner {
        _pause();
    }
	
    function unpause() public onlyOwner {
        _unpause();
    }
}