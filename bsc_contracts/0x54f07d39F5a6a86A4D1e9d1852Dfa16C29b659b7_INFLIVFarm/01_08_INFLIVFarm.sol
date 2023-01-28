// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IGovernance {
   function distributeFee(uint256 amount) external;
}

interface IPancakeSwapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IReferrals {
    function addMember(address member, address parent) external;
    function getSponsor(address account) external view returns (address);
}

contract INFLIVFarm is Initializable, OwnableUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
	
	address[2] public stakedToken;
	address public rewardToken;
	address public pancakeSwapV2Router;
	address public USDT;
	
	uint256[21] public referrerBonus;
	IReferrals public Referrals;
	
	struct UserInfo {
	   uint256 farm; 
	   uint256 amount; 
	   uint256 rewardDebt;
	   uint256 startTime;
	   uint256 endTime;
	   mapping(uint256 => DepositDetails[]) deposit;
    }
	
	struct DepositDetails{
	  uint256 startTime;
	  uint256 endTime;
	  uint256 amount;
      uint256 locked;	   
	}
	
	uint256 public totalStaked;
	uint256 public accTokenPerShare;
	uint256 public governanceFeeonHarvest;
	uint256 public governanceFeeOnActivation;
	uint256 public precisionFactor;
	
	uint256[8] public activationFee;
	uint256[8] public maxStakingToken;
	
	mapping(address => mapping(uint256 => UserInfo)) public mapUserInfo;
	mapping(address => uint256) public stakingCount;
	mapping(address => uint256) public lastActiveTime;
	mapping(address => uint256) public referralEarning;
	
    event MigrateTokens(address tokenRecovered, address receiver, uint256 amount);
    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
	event NewMaxStakingToken(uint256 P1MaxStaking, uint256 P2MaxStaking, uint256 P3MaxStaking, uint256 P4MaxStaking, uint256 P5MaxStaking, uint256 P6MaxStaking, uint256 P7MaxStaking);
	event NewRewardTokenUpdated(address tokenAddress);
	event NewStakingTokenUpdated(address BNBIFV, address USDTIFV);
	event PoolUpdated(uint256 amount);	
	event buyFarm(address user, uint256 package);
	
    function initialize() public initializer {
		__Ownable_init();
		
		governanceFeeonHarvest = 500;
		governanceFeeOnActivation = 3000 + 1050;
		
		activationFee[0] = 0;
		activationFee[1] = 25 * 10**18;
		activationFee[2] = 50 * 10**18;
		activationFee[3] = 100 * 10**18;
		activationFee[4] = 200 * 10**18;
		activationFee[5] = 500 * 10**18;
		activationFee[6] = 1000 * 10**18;
		activationFee[7] = 2000 * 10**18;
		
		maxStakingToken[0] = 30 * 10**18;
		maxStakingToken[1] = 35 * 10**18;
		maxStakingToken[2] = 80 * 10**18;
		maxStakingToken[3] = 200 * 10**18;
		maxStakingToken[4] = 500 * 10**18;
		maxStakingToken[5] = 1500 * 10**18;
		maxStakingToken[6] = 3500 * 10**18;
		maxStakingToken[7] = 9000 * 10**18;
		
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
	   path[1] = address(rewardToken);
	   
	   uint256[] memory INFLIVRequired = IPancakeSwapV2Router(pancakeSwapV2Router).getAmountsOut(amountIn, path);
	   return INFLIVRequired[1];
    }
	
	function activePackage(uint256 package, address sponsor) external{
		require(package < activationFee.length && package > 0, "Farm Plan not found");
		require(sponsor != address(0), 'zero address');
		require(sponsor != msg.sender, "ERR: referrer different required");
		
		lastActiveTime[msg.sender] = block.timestamp; 
		stakingCount[msg.sender] += 1;
		
		uint256 tokenRequired = getQuotes(activationFee[package]);
		uint256 stakingID = stakingCount[msg.sender];
		
		require(IERC20Upgradeable(rewardToken).balanceOf(msg.sender) >= tokenRequired, "balance not available for activation");
		
		mapUserInfo[msg.sender][stakingID].startTime = block.timestamp;
		mapUserInfo[msg.sender][stakingID].endTime = block.timestamp + 365 days;
		mapUserInfo[msg.sender][stakingID].farm = package;
		
		IERC20Upgradeable(rewardToken).safeTransferFrom(address(msg.sender), address(this), tokenRequired);
		
		uint256 governanceTax  = tokenRequired * governanceFeeOnActivation / 10000;
		uint256 referralReward = tokenRequired - governanceTax;
		
		IGovernance(rewardToken).distributeFee(governanceTax);
		if(Referrals.getSponsor(msg.sender) == address(0)) 
		{
		    Referrals.addMember(msg.sender, sponsor);
		}
		if(stakingCount[msg.sender]==1)
		{
		    lastActiveTime[Referrals.getSponsor(msg.sender)] = block.timestamp;
		}
		referralUpdate(msg.sender, referralReward);
		emit buyFarm(msg.sender, package);
    }
	
	function referralUpdate(address sponsor, uint256 amount) private {
		address nextReferrer = Referrals.getSponsor(sponsor);
		
		uint256 i;
		uint256 level = 0;
		uint256 amountUsed = 0;
		for(i=0; i < 256; i++) 
		{
			if(nextReferrer != address(0) && nextReferrer != address(rewardToken)) 
			{   
                if(lastActiveTime[nextReferrer] + 30 days >= block.timestamp && level <= 20)
				{
				    uint256 reward = amount * referrerBonus[level] / 10000;
				    IERC20Upgradeable(rewardToken).safeTransfer(address(nextReferrer), reward);
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
		   IGovernance(rewardToken).distributeFee(governanceTax);
	    }
    }
	
	function createTeam(address sponsor) external {
		require(sponsor != address(0), "zero address");
		require(sponsor != msg.sender, "ERR: referrer different required");
		require(Referrals.getSponsor(msg.sender) == address(0), "sponsor already exits");
		
		Referrals.addMember(msg.sender, sponsor);
    }
	
	function deposit(uint256 amount, uint256 stakingID) external {
	    require(maxStakingToken[mapUserInfo[msg.sender][stakingID].farm] >= mapUserInfo[msg.sender][stakingID].amount + amount, "amount is more than max staking amount");
		
		uint256 pending;
		if(stakingID == 0)
		{
			if(mapUserInfo[msg.sender][stakingID].amount > 0) 
			{
			   pending = pendingReward(msg.sender, stakingID);
			   if(pending > 0) 
			   {
			       uint256 governanceTax = pending * governanceFeeonHarvest / 10000;
				   mapUserInfo[msg.sender][stakingID].rewardDebt += pending;
				   IERC20Upgradeable(rewardToken).safeTransfer(address(msg.sender), pending - governanceTax);
				   
				   pending = pendingReward(msg.sender, stakingID);
				   if(pending > 0) 
				   {
				      governanceTax += pending * governanceFeeonHarvest / 10000;
					  IERC20Upgradeable(rewardToken).safeTransfer(address(msg.sender), pending - (pending * governanceFeeonHarvest / 10000));
				   }
				   IGovernance(rewardToken).distributeFee(governanceTax);
			   }
			}
			else
			{
				mapUserInfo[msg.sender][stakingID].startTime = block.timestamp;
			}
			mapUserInfo[msg.sender][stakingID].amount += amount;
			mapUserInfo[msg.sender][stakingID].rewardDebt = (mapUserInfo[msg.sender][stakingID].amount * accTokenPerShare) / precisionFactor;
			totalStaked += amount;
			IERC20Upgradeable(stakedToken[0]).safeTransferFrom(address(msg.sender), address(this), amount);
		} 
		else 
		{
		    require(mapUserInfo[msg.sender][stakingID].endTime >= block.timestamp, "Farm filling time is already completed");
			
			if(mapUserInfo[msg.sender][stakingID].amount > 0) 
			{
			   pending = pendingReward(msg.sender, stakingID);
			   if(pending > 0) 
			   {
			       uint256 governanceTax = pending * governanceFeeonHarvest / 10000;
				   mapUserInfo[msg.sender][stakingID].rewardDebt += pending;
				   IERC20Upgradeable(rewardToken).safeTransfer(address(msg.sender), pending - governanceTax);
				   
				   pending = pendingReward(msg.sender, stakingID);
				   if(pending > 0) 
				   {
				       governanceTax += pending * governanceFeeonHarvest / 10000;
					   IERC20Upgradeable(rewardToken).safeTransfer(address(msg.sender), pending - (pending * governanceFeeonHarvest / 10000));
				   }
				   IGovernance(rewardToken).distributeFee(governanceTax);
			   }
			}
			mapUserInfo[msg.sender][stakingID].amount += amount;
			mapUserInfo[msg.sender][stakingID].rewardDebt = (mapUserInfo[msg.sender][stakingID].amount * accTokenPerShare) / precisionFactor;
			totalStaked += amount;
			if(mapUserInfo[msg.sender][stakingID].farm > 2)
			{
			    mapUserInfo[msg.sender][stakingID].deposit[stakingID].push(DepositDetails(block.timestamp, block.timestamp + 2 days, amount, 1));
			    IERC20Upgradeable(stakedToken[1]).safeTransferFrom(address(msg.sender), address(this), amount);
			}
			else
			{
			    mapUserInfo[msg.sender][stakingID].deposit[stakingID].push(DepositDetails(block.timestamp, block.timestamp + 2 days, amount, 1));
			    IERC20Upgradeable(stakedToken[0]).safeTransferFrom(address(msg.sender), address(this), amount);
			}
		}
        emit Deposit(msg.sender, amount);
    }
	
	function getDepositDetails(address user, uint256 stakingID) external view returns(DepositDetails[] memory _deposit) {
        DepositDetails[] storage deposits = mapUserInfo[user][stakingID].deposit[stakingID];
        return deposits;
    }
	
	function withdrawReward(uint256[] calldata stakingID) external {
		for(uint i=0; i < stakingID.length; i++)
		{
		    if(mapUserInfo[msg.sender][stakingID[i]].amount > 0) 
			{
				uint256 pending = pendingReward(msg.sender, stakingID[i]);
				if (pending > 0) 
				{
				   uint256 governanceTax = pending * governanceFeeonHarvest / 10000;
				   IGovernance(rewardToken).distributeFee(governanceTax);
				   
				   mapUserInfo[msg.sender][stakingID[i]].rewardDebt += pending;
				   
				   IERC20Upgradeable(rewardToken).safeTransfer(address(msg.sender), pending - governanceTax);
				   emit Withdraw(msg.sender, pending);
				}
			}
		}
    }
	
	function withdraw(uint256 stakingID, uint256[] calldata ids) external{
	    if(mapUserInfo[msg.sender][stakingID].amount > 0) 
		{
		   uint256 pending = pendingReward(msg.sender, stakingID);
		   uint256 amount;
		   if(stakingID == 0)
		   {   
			   amount = mapUserInfo[msg.sender][stakingID].amount;
			   totalStaked -= amount;
			   mapUserInfo[msg.sender][stakingID].amount = 0;
			   mapUserInfo[msg.sender][stakingID].rewardDebt = 0;
			   IERC20Upgradeable(stakedToken[0]).safeTransfer(address(msg.sender), amount);
		   }
		   else
		   {
			   require(ids.length > 0, "No deposit id found");
			   for(uint i=0; i < ids.length; i++)
			   {
				   if(mapUserInfo[msg.sender][stakingID].deposit[stakingID][ids[i]].locked == 1 && mapUserInfo[msg.sender][stakingID].deposit[stakingID][ids[i]].endTime <= block.timestamp)
				   {
					  amount = mapUserInfo[msg.sender][stakingID].deposit[stakingID][ids[i]].amount;
					  totalStaked -= amount;
					  mapUserInfo[msg.sender][stakingID].deposit[stakingID][ids[i]].locked = 0;
					  mapUserInfo[msg.sender][stakingID].amount -= amount;
					  if(mapUserInfo[msg.sender][stakingID].farm == 1 || mapUserInfo[msg.sender][stakingID].farm == 2)
					  {
						  IERC20Upgradeable(stakedToken[0]).safeTransfer(address(msg.sender), amount);
					  }
					  else
					  {
						  IERC20Upgradeable(stakedToken[1]).safeTransfer(address(msg.sender), amount);
					  }
				   }
			   }
			   mapUserInfo[msg.sender][stakingID].rewardDebt = (mapUserInfo[msg.sender][stakingID].amount * accTokenPerShare) / precisionFactor;
		   }
		   if(pending > 0) 
		   {
			   uint256 governanceTax = pending * governanceFeeonHarvest / 10000;
			   IGovernance(rewardToken).distributeFee(governanceTax);
			   IERC20Upgradeable(rewardToken).safeTransfer(address(msg.sender), pending - governanceTax);
		   }
		   emit Withdraw(msg.sender, amount);
        }
    }
	
	function updatePool(uint256 amount) external{
		require(address(msg.sender) == address(rewardToken), "Request source is not valid");
		if(totalStaked > 0)
		{
		   accTokenPerShare = accTokenPerShare + (amount * precisionFactor / totalStaked);
		}
		emit PoolUpdated(amount);
    }
	
	function pendingReward(address user, uint256 stakingID) public view returns (uint256) {
		if(mapUserInfo[user][stakingID].amount > 0) 
		{
            uint256 pending = ((mapUserInfo[user][stakingID].amount * accTokenPerShare) / precisionFactor) - mapUserInfo[user][stakingID].rewardDebt;
			return pending;
        } 
		else 
		{
		   return 0;
		}
    }
	
	function migrateTokens(address tokenAddress, address receiver, uint256 tokenAmount) external onlyOwner{
       require(tokenAddress != address(0), "Zero address");
	   require(receiver != address(0), "Zero address");
	   require(IERC20Upgradeable(tokenAddress).balanceOf(address(this)) >= tokenAmount, "Insufficient balance on contract");
	   
	   IERC20Upgradeable(tokenAddress).safeTransfer(address(receiver), tokenAmount);
       emit MigrateTokens(tokenAddress, receiver, tokenAmount);
    }
	
	function setRewardToken(address tokenAddress) external onlyOwner{
       require(tokenAddress != address(0), "Zero address");
	   rewardToken = tokenAddress;
	   
	   emit NewRewardTokenUpdated(rewardToken);
    }
	
	function setStakingToken(address BNBIFV, address USDTIFV) external onlyOwner{
       require(BNBIFV != address(0), "Zero address");
	   require(USDTIFV != address(0), "Zero address");
	   
	   stakedToken[0] = BNBIFV;
	   stakedToken[1] = USDTIFV;
	   emit NewStakingTokenUpdated(BNBIFV, USDTIFV);
    }
	
	function SetMaxStakingToken(uint256 P1MaxStaking, uint256 P2MaxStaking, uint256 P3MaxStaking, uint256 P4MaxStaking, uint256 P5MaxStaking, uint256 P6MaxStaking, uint256 P7MaxStaking, uint256 P8MaxStaking) external onlyOwner {
	    require(P1MaxStaking > 0, "Incorrect `P1 Max Staking` value");
		require(P2MaxStaking > 0, "Incorrect `P2 Max Staking` value");
		require(P3MaxStaking > 0, "Incorrect `P3 Max Staking` value");
		require(P4MaxStaking > 0, "Incorrect `P4 Max Staking` value");
		require(P5MaxStaking > 0, "Incorrect `P5 Max Staking` value");
		require(P6MaxStaking > 0, "Incorrect `P6 Max Staking` value");
		require(P7MaxStaking > 0, "Incorrect `P7 Max Staking` value");
		require(P8MaxStaking > 0, "Incorrect `P8 Max Staking` value");
		
	    maxStakingToken[0] = P1MaxStaking;
        maxStakingToken[1] = P2MaxStaking;
        maxStakingToken[2] = P3MaxStaking;
		maxStakingToken[3] = P4MaxStaking;
		maxStakingToken[4] = P5MaxStaking;
		maxStakingToken[5] = P6MaxStaking;
		maxStakingToken[6] = P7MaxStaking;
		maxStakingToken[7] = P8MaxStaking;
		
		emit NewMaxStakingToken(P1MaxStaking, P2MaxStaking, P3MaxStaking, P4MaxStaking, P5MaxStaking, P6MaxStaking, P7MaxStaking);
    }
	
	function isActive(address user) external view returns(bool)
	{
	   if((lastActiveTime[user] + 30 days) >= block.timestamp)
	   {
	       return true;
	   }
	   else
	   {
	       return false;
	   }
	}
}