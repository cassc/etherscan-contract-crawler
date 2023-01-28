// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IGovernance {
   function distributeFee(uint256 amount) external;
}

interface IReferrals {
    function addMember(address member, address parent) external;
    function getSponsor(address account) external view returns (address);
}

interface IPancakeSwapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract INFLIVStaking is Initializable, OwnableUpgradeable{
	using SafeERC20Upgradeable for IERC20Upgradeable;
	
	address public stakedToken;
	address public pancakeSwapV2Router;
	address public USDT;
	
	uint256[21] public referrerBonus;
	IReferrals public Referrals;
	
	struct UserInfo{
	  uint256 amount; 
	  uint256 rewardDebt;
	  uint256 claimed;
	  uint256 startTime;
    }
	
	uint256 public totalStaked;
	uint256 public accTokenPerShare;
	uint256 public governanceFeeonHarvest;
	uint256 public governanceFeeOnActivation;
	uint256 public precisionFactor;
	
	uint256[5] public stakingPeriod;
	uint256[5] public minStakingToken;
	uint256[5] public maxStakingToken;
	uint256[2] public activationFee;
	
	mapping(address => mapping(uint256 => UserInfo)) public mapUserInfo;
	mapping(address => uint256) public stakingCount;
	mapping(address => uint256) public nextActiveTime;
	mapping(address => uint256) public nextPackageTime;
	mapping(address => uint256) public lastActivePackage;
	mapping(address => uint256) public referralEarning;
	
    event MigrateTokens(address tokenRecovered, address receiver, uint256 amount);
    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
	event NewMinStakingToken(uint256 P1MinStaking, uint256 P2MinStaking, uint256 P3MinStaking, uint256 P4MinStaking, uint256 P5MinStaking);
	event NewMaxStakingToken(uint256 P1MaxStaking, uint256 P2MaxStaking, uint256 P3MaxStaking, uint256 P4MaxStaking, uint256 P5MaxStaking);
	event NewStakingPeriod(uint256 P1StakingPeriod, uint256 P2StakingPeriod, uint256 P3StakingPeriod, uint256 P4StakingPeriod, uint256 P5StakingPeriod);
	event NewStakingTokenUpdated(address tokenAddress);
	event NewGovernanceFeeUpdated(uint256 newFee);
	event PoolUpdated(uint256 amount);
    event buyStaking(address user, uint256 package);	
	
    function initialize() public initializer {
		__Ownable_init();
		
		governanceFeeonHarvest = 500;
		governanceFeeOnActivation = 3000 + 1050;
		
		activationFee[0] = 10 * 10**18;
		activationFee[1] = 300 * 10**18;
		
		stakingPeriod[0] = 30 days;
		stakingPeriod[1] = 60 days;
		stakingPeriod[2] = 90 days;
		stakingPeriod[3] = 180 days;
		stakingPeriod[4] = 365 days;
		
		minStakingToken[0] = 10 * 10**18;
		minStakingToken[1] = 10 * 10**18;
		minStakingToken[2] = 10 * 10**18;
		minStakingToken[3] = 10 * 10**18;
		minStakingToken[4] = 10 * 10**18;
		
		maxStakingToken[0] = 6000 * 10**18;
		maxStakingToken[1] = 20000 * 10**18;
		maxStakingToken[2] = 50000 * 10**18;
		maxStakingToken[3] = 200000 * 10**18;
		maxStakingToken[4] = 500000 * 10**18;
		
		referrerBonus[0]  = 2857;
		referrerBonus[1]  = 1000;
		referrerBonus[2]  = 429;
		referrerBonus[3]  = 429;
		referrerBonus[4]  = 1000;
		referrerBonus[5]  = 143;
		referrerBonus[6]  = 143;
		referrerBonus[7]  = 143;
		referrerBonus[8]  = 143;
		referrerBonus[9]  = 858;
		referrerBonus[10] = 143;
		referrerBonus[11] = 143;
		referrerBonus[12] = 143;
		referrerBonus[13] = 143;
		referrerBonus[14] = 858;
		referrerBonus[15] = 143;
		referrerBonus[16] = 143;
		referrerBonus[17] = 143;
		referrerBonus[18] = 143;
		referrerBonus[19] = 143;
		referrerBonus[20] = 710;
		
		precisionFactor = 10**18;

		pancakeSwapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		Referrals = IReferrals(0x767C45a6653793e4f71840B0177EEaE37e6F5ab2);
		USDT = address(0x55d398326f99059fF775485246999027B3197955);
    }
	
	function getQuotes(uint256 amountIn) public view returns (uint256){
	   address[] memory path = new address[](2);
       path[0] = address(USDT);
	   path[1] = address(stakedToken);
	   
	   uint256[] memory INFLIVRequired = IPancakeSwapV2Router(pancakeSwapV2Router).getAmountsOut(amountIn, path);
	   return INFLIVRequired[1];
    }
	
	function activePackage(uint256 package, address sponsor) external{
		require(package < activationFee.length, "Staking Plan not found");
		require(sponsor != address(0), 'zero address');
		require(sponsor != msg.sender, "ERR: referrer different required");
		if(lastActivePackage[msg.sender] == 1)
		{
		    require(block.timestamp >= nextPackageTime[msg.sender], "ERR: package already active");
		}
		uint256 addonTime = package == 1 ? 365 days : 30 days; 
		nextPackageTime[msg.sender] = block.timestamp + addonTime; 
		stakingCount[msg.sender] += 1;
		
		uint256 tokenRequired = getQuotes(activationFee[package]);
		require(IERC20Upgradeable(stakedToken).balanceOf(msg.sender) >= tokenRequired, "balance not available for activation");
		IERC20Upgradeable(stakedToken).safeTransferFrom(address(msg.sender), address(this), tokenRequired);
		
		uint256 governanceTax  = tokenRequired * governanceFeeOnActivation / 10000;
		uint256 referralReward = tokenRequired - governanceTax;
		
		IGovernance(stakedToken).distributeFee(governanceTax);
		if(Referrals.getSponsor(msg.sender) == address(0)) 
		{
		    Referrals.addMember(msg.sender, sponsor);
		}
		if(stakingCount[msg.sender]==1 && (block.timestamp + addonTime) >= nextActiveTime[Referrals.getSponsor(msg.sender)])
		{   
		    nextActiveTime[Referrals.getSponsor(msg.sender)] = block.timestamp + addonTime;
		}
		if((block.timestamp + addonTime) >= nextActiveTime[msg.sender])
		{   
		    nextActiveTime[msg.sender] = block.timestamp + addonTime;
		}
		
		lastActivePackage[msg.sender] = package;
		referralUpdate(msg.sender, referralReward);
		emit buyStaking(msg.sender, package);
    }
	
	function referralUpdate(address sponsor, uint256 amount) private {
		address nextReferrer = Referrals.getSponsor(sponsor);
		
		uint256 i;
		uint256 level = 0;
		uint256 amountUsed = 0;
		for(i=0; i < 256; i++) 
		{
			if(nextReferrer != address(0) && nextReferrer != address(stakedToken)) 
			{   
                if(nextActiveTime[nextReferrer] >= block.timestamp && level <= 20)
				{
				    uint256 reward = amount * referrerBonus[level] / 10000;
				    IERC20Upgradeable(stakedToken).safeTransfer(address(nextReferrer), reward);
				    amountUsed += reward;
					referralEarning[address(nextReferrer)] += reward;
				    level++;
				}
				else if(level == 21)
				{
				   break;     
				}
			}
			else 
			{
		        break;
			}
		    nextReferrer = Referrals.getSponsor(nextReferrer);
		}
		uint256 governanceTax = amount > amountUsed ? amount - amountUsed : 0;
	    if(governanceTax > 0) 
		{
		   IGovernance(stakedToken).distributeFee(governanceTax);
	    }
    }
	
	function deposit(uint256 amount, uint256 plan) external{
		require(plan < stakingPeriod.length, "Staking Plan not found");
		require(IERC20Upgradeable(stakedToken).balanceOf(msg.sender) >= amount, "balance not available for staking");
		
		if(block.timestamp >= nextPackageTime[msg.sender] || lastActivePackage[msg.sender] == 0)
		{
		   require(amount >= minStakingToken[plan], "amount is less than minimum staking amount");
		   require(maxStakingToken[plan] >= mapUserInfo[msg.sender][plan].amount + amount, "amount is more than max staking amount");
		}
		
		uint256 pending;
		uint256 governanceTax;
		
		IERC20Upgradeable(stakedToken).safeTransferFrom(address(msg.sender), address(this), amount);
		if(mapUserInfo[msg.sender][plan].amount > 0) 
		{
            pending = pendingReward(msg.sender, plan);
            if(pending > 0)
			{
			    governanceTax = pending * governanceFeeonHarvest / 10000;
			    IGovernance(stakedToken).distributeFee(governanceTax);
                IERC20Upgradeable(stakedToken).safeTransfer(address(msg.sender), pending - governanceTax);
            }
        }
		
		totalStaked += amount;
		mapUserInfo[msg.sender][plan].amount += amount;
		mapUserInfo[msg.sender][plan].startTime = block.timestamp;
		mapUserInfo[msg.sender][plan].rewardDebt = mapUserInfo[msg.sender][plan].amount * accTokenPerShare / precisionFactor;
		mapUserInfo[msg.sender][plan].claimed += (pending - governanceTax);
		
        emit Deposit(msg.sender, amount);
    }
	
	function withdrawReward(uint256 plan) external{
		if(mapUserInfo[msg.sender][plan].amount > 0) 
		{
            uint256 pending = pendingReward(msg.sender, plan);
			if(pending > 0) 
			{
			   uint256 governanceTax = pending * governanceFeeonHarvest / 10000;
			   IGovernance(stakedToken).distributeFee(governanceTax);
			   
			   IERC20Upgradeable(stakedToken).safeTransfer(address(msg.sender), pending - governanceTax);
			   
			   mapUserInfo[msg.sender][plan].claimed += (pending - governanceTax);
			   mapUserInfo[msg.sender][plan].rewardDebt += pending;
			   emit Withdraw(msg.sender, pending);
            }
        } 
    }
	
	function withdraw(uint256 plan) external{
	    if(mapUserInfo[msg.sender][plan].amount > 0) 
		{
			if(mapUserInfo[msg.sender][plan].startTime + stakingPeriod[plan] >= block.timestamp &&  block.timestamp >= nextPackageTime[msg.sender]) 
			{
			    totalStaked -= mapUserInfo[msg.sender][plan].amount;
			    uint256 pending = pendingReward(msg.sender, plan);
				uint256 governanceTax = pending * governanceFeeonHarvest / 10000;
			    uint256 penalty = (mapUserInfo[msg.sender][plan].claimed + (pending - governanceTax)) / 2;
				if((penalty + governanceTax) > 0)
				{
				   IGovernance(stakedToken).distributeFee(penalty + governanceTax);
				}
			    IERC20Upgradeable(stakedToken).safeTransfer(address(msg.sender), (mapUserInfo[msg.sender][plan].amount + pending) - (governanceTax + penalty));
				
				mapUserInfo[msg.sender][plan].claimed = 0;
				mapUserInfo[msg.sender][plan].startTime = 0;
				mapUserInfo[msg.sender][plan].amount = 0;
				mapUserInfo[msg.sender][plan].rewardDebt = 0;
				
				emit Withdraw(msg.sender, pending + mapUserInfo[msg.sender][plan].amount - penalty);
            }
			else
			{
			    totalStaked -= mapUserInfo[msg.sender][plan].amount;
			    uint256 pending = pendingReward(msg.sender, plan);
			   	uint256 governanceTax = pending * governanceFeeonHarvest / 10000;
				if(governanceTax > 0)
				{
				   IGovernance(stakedToken).distributeFee(governanceTax);
				}
			    IERC20Upgradeable(stakedToken).safeTransfer(address(msg.sender), (pending + mapUserInfo[msg.sender][plan].amount) - governanceTax);
				
			    mapUserInfo[msg.sender][plan].claimed = 0;
				mapUserInfo[msg.sender][plan].startTime = 0;
				mapUserInfo[msg.sender][plan].amount = 0;
				mapUserInfo[msg.sender][plan].rewardDebt = 0;
			    emit Withdraw(msg.sender, (pending + mapUserInfo[msg.sender][plan].amount));
			}
        } 
    }
	
	function updatePool(uint256 amount) external{
		require(address(msg.sender) == address(stakedToken), "Request source is not valid");
		if(totalStaked > 0)
		{
		    accTokenPerShare = accTokenPerShare + (amount * precisionFactor / totalStaked);
		}
		emit PoolUpdated(amount);
    }
	
	function pendingReward(address user, uint256 plan) public view returns (uint256) {
		if(mapUserInfo[user][plan].amount > 0) 
		{
            uint256 pending = ((mapUserInfo[user][plan].amount * accTokenPerShare) / precisionFactor) - mapUserInfo[user][plan].rewardDebt;
			return pending;
        } 
		else 
		{
		   return 0;
		}
    }
	
	function createTeam(address sponsor) external {
		require(sponsor != address(0), "zero address");
		require(sponsor != msg.sender, "ERR: referrer different required");
		require(Referrals.getSponsor(msg.sender) == address(0), "sponsor already exits");
		
		Referrals.addMember(msg.sender, sponsor);
    }
	
	function migrateTokens(address tokenAddress, address receiver, uint256 tokenAmount) external onlyOwner{
       require(tokenAddress != address(0), "Zero address");
	   require(receiver != address(0), "Zero address");
	   require(IERC20Upgradeable(tokenAddress).balanceOf(address(this)) >= tokenAmount, "Insufficient balance on contract");
	   
	   IERC20Upgradeable(tokenAddress).safeTransfer(address(receiver), tokenAmount);
       emit MigrateTokens(tokenAddress, receiver, tokenAmount);
    }
	
	function setStakingToken(address tokenAddress) external onlyOwner{
       require(tokenAddress != address(0), "Zero address");
	   stakedToken = tokenAddress;
	   
	   IERC20Upgradeable(stakedToken).approve(address(stakedToken), type(uint256).max);
	   emit NewStakingTokenUpdated(tokenAddress);
    }
	
	function SetMinStakingToken(uint256 P1MinStaking, uint256 P2MinStaking, uint256 P3MinStaking, uint256 P4MinStaking, uint256 P5MinStaking) external onlyOwner {
	    require(P1MinStaking > 0, "Incorrect `P1 Min Staking` value");
		require(P2MinStaking > 0, "Incorrect `P2 Min Staking` value");
		require(P3MinStaking > 0, "Incorrect `P3 Min Staking` value");
		require(P4MinStaking > 0, "Incorrect `P4 Min Staking` value");
		require(P5MinStaking > 0, "Incorrect `P5 Min Staking` value");
		
	    minStakingToken[0] = P1MinStaking;
        minStakingToken[1] = P2MinStaking;
        minStakingToken[2] = P3MinStaking;
		minStakingToken[3] = P4MinStaking;
		minStakingToken[4] = P5MinStaking;
		
		emit NewMinStakingToken(P1MinStaking, P2MinStaking, P3MinStaking, P4MinStaking, P5MinStaking);
    }
	
	function SetMaxStakingToken(uint256 P1MaxStaking, uint256 P2MaxStaking, uint256 P3MaxStaking, uint256 P4MaxStaking, uint256 P5MaxStaking) external onlyOwner {
	    require(P1MaxStaking > 0, "Incorrect `P1 Max Staking` value");
		require(P2MaxStaking > 0, "Incorrect `P2 Max Staking` value");
		require(P3MaxStaking > 0, "Incorrect `P3 Max Staking` value");
		require(P4MaxStaking > 0, "Incorrect `P4 Max Staking` value");
		require(P5MaxStaking > 0, "Incorrect `P5 Max Staking` value");
		
	    maxStakingToken[0] = P1MaxStaking;
        maxStakingToken[1] = P2MaxStaking;
        maxStakingToken[2] = P3MaxStaking;
		maxStakingToken[3] = P4MaxStaking;
		maxStakingToken[4] = P5MaxStaking;
		
		emit NewMaxStakingToken(P1MaxStaking, P2MaxStaking, P3MaxStaking, P4MaxStaking, P5MaxStaking);
    }
	
	function isActive(address user) external view returns(bool)
	{
	   if(nextActiveTime[user] >= block.timestamp)
	   {
	       return true;
	   }
	   else
	   {
	       return false;
	   }
	}
	
	function isPackageActive(address user) external view returns(bool)
	{
	   if(nextPackageTime[user] >= block.timestamp)
	   {
	       return true;
	   }
	   else
	   {
	       return false;
	   }
	}
}