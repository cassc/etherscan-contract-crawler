// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/utils/math/SafeMath.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/access/Ownable.sol";

contract SmartCashCapital is Context, Ownable {
    
    using SafeMath for uint256;
    
    uint256 constant partner = 30;
    uint256 constant development = 70;
    uint256 constant hardDays = 1 days;
    uint256 constant refPercentage = 30;
    uint256 constant minInvest = 50 ether;
    uint256 constant percentDivider = 1000;
    uint256 constant maxRewards = 2000 ether;

    uint256 private usersTotal;
    uint256 private compounds;
    uint256 private dateLaunched;
    uint256 private ovrTotalDeps;
    uint256 private ovrTotalComp;
    uint256 private ovrTotalWiths;
    
    uint256 private lastDepositTimeStep = 2 hours;
    uint256 private lastBuyCurrentRound = 1;
    uint256 private lastDepositPoolBalance;
    uint256 private lastDepositLastDrawAction;
    address private lastDepositPotentialWinner;

    address private previousPoolWinner;
    uint256 private previousPoolRewards;

    bool private initialized;
    bool private lastDepositEnabled;

    struct User {
        uint256 startDate;
        uint256 divs;
        uint256 refBonus;
        uint256 totalInvested;
        uint256 totalWithdrawn;
        uint256 totalCompounded;
        uint256 lastWith;
        uint256 timesCmpd;
        uint256 keyCounter;
        uint256 activeStakesCount;
        DepositList [] depoList;
    }

    struct DepositList {
        uint256 key;
        uint256 depoTime;
        uint256 amt;
        address ref;
        bool initialWithdrawn;
    }

    struct DivPercs{
        uint256 daysInSeconds;
        uint256 divsPercentage;
        uint256 feePercentage;
    }

    mapping (address => User) public users;
    mapping (uint256 => DivPercs) public PercsKey;

	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
    event Reinvested(address indexed user, uint256 amount);
	event WithdrawnInitial(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
    event LastBuyPayout(uint256 indexed round, address indexed addr, uint256 amount, uint256 timestamp);

    address private immutable developmentAddress; 
    address private immutable partnershipAddress; //R, V, P, M

    ERC20 private BUSD = ERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    constructor(address dev, address part) {
            developmentAddress = dev;
            partnershipAddress = part;
            PercsKey[10] = DivPercs(20 days, 10, 300);
            PercsKey[20] = DivPercs(40 days, 15, 250);
            PercsKey[30] = DivPercs(60 days, 20, 200);
            PercsKey[40] = DivPercs(80 days, 25, 150);
            PercsKey[50] = DivPercs(100 days,30, 100);
            PercsKey[60] = DivPercs(100 days,35,  50);
    }

    modifier isInitialized() {
        require(initialized, "Contract not initialized.");
        _;
    }
    
    function launch(address addr, uint256 amount) public onlyOwner {
        require(!initialized, "Contract already launched.");
        initialized = true;
        lastDepositEnabled = true;
        lastDepositLastDrawAction = block.timestamp;
        dateLaunched = block.timestamp;
        invest(addr, amount);
    }

    function invest(address ref, uint256 amount) public isInitialized {
        require(amount >= minInvest, "Minimum investment not reached.");
        
        BUSD.transferFrom(msg.sender, address(this), amount);
        User storage user = users[msg.sender];

        if (user.lastWith <= 0){
            user.lastWith = block.timestamp;
            user.startDate = block.timestamp;
        }

        if(user.depoList.length == 0) usersTotal++;
        
        uint256 devStakeFee  = amount.mul(development).div(percentDivider); 
        uint256 partStakeFee = amount.mul(partner).div(percentDivider);
        uint256 adjustedAmt  = amount.sub(devStakeFee + partStakeFee); 
        
        user.totalInvested += adjustedAmt; 
        uint256 refAmount = adjustedAmt.mul(refPercentage).div(percentDivider);
        if(ref == msg.sender) ref = address(0);
        if (ref != 0x000000000000000000000000000000000000dEaD || ref != address(0)) users[ref].refBonus += refAmount;

        user.depoList.push(DepositList(user.depoList.length,  block.timestamp, adjustedAmt, ref, false));
        
        user.keyCounter++;
        user.activeStakesCount++;
        ovrTotalDeps += adjustedAmt;
        
        BUSD.transfer(developmentAddress, devStakeFee);
        BUSD.transfer(partnershipAddress, partStakeFee);
        
        drawLastDepositWinner();
        poolLastDeposit(msg.sender, amount);

        emit RefBonus(ref, msg.sender, amount);
        emit NewDeposit(msg.sender, amount);
    }

    function poolLastDeposit(address userAddress, uint256 amount) private {
        if(!lastDepositEnabled) return;

        uint256 poolShare = amount.mul(10).div(percentDivider);

        lastDepositPoolBalance = lastDepositPoolBalance.add(poolShare) > maxRewards ? 
        lastDepositPoolBalance.add(maxRewards.sub(lastDepositPoolBalance)) : lastDepositPoolBalance.add(poolShare);
        lastDepositPotentialWinner = userAddress;
        lastDepositLastDrawAction  = block.timestamp;
    } 

    function drawLastDepositWinner() public {
        if(lastDepositEnabled && block.timestamp.sub(lastDepositLastDrawAction) >= lastDepositTimeStep && lastDepositPotentialWinner != address(0)) {
                        
            uint256 devStakeFee  = lastDepositPoolBalance.mul(development).div(percentDivider); 
            uint256 partStakeFee = lastDepositPoolBalance.mul(partner).div(percentDivider);
            uint256 adjustedAmt  = lastDepositPoolBalance.sub(devStakeFee + partStakeFee);
            BUSD.transfer(lastDepositPotentialWinner, adjustedAmt);
            emit LastBuyPayout(lastBuyCurrentRound, lastDepositPotentialWinner, adjustedAmt, block.timestamp);

            
            previousPoolWinner         = lastDepositPotentialWinner;
            previousPoolRewards        = adjustedAmt;
            lastDepositPoolBalance     = 0;
            lastDepositPotentialWinner = address(0);
            lastDepositLastDrawAction  = block.timestamp; 
            lastBuyCurrentRound++;
        }
    }

    function investRefBonus() public isInitialized { 
        User storage user = users[msg.sender];
        require(user.depoList.length > 0, "User needs to have atleast 1 stake before reinvesting referral rewards.");
        require(user.refBonus > 0, "User has no referral rewards to stake.");

        user.depoList.push(DepositList(user.keyCounter,  block.timestamp, user.refBonus, address(0), false));
        
        ovrTotalComp += user.refBonus;
        user.totalInvested += user.refBonus;
        user.totalCompounded += user.refBonus;
        user.refBonus = 0;
        user.keyCounter++;
        user.activeStakesCount++;

	    emit Reinvested(msg.sender, user.refBonus);
    }

  	function reinvest() public isInitialized {
        User storage user = users[msg.sender];

        uint256 y = getUserDividends(msg.sender);

        for (uint i = 0; i < user.depoList.length; i++){
          if (!user.depoList[i].initialWithdrawn) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        user.depoList.push(DepositList(user.keyCounter,  block.timestamp, y, address(0), false));  

        ovrTotalComp += y;
        user.totalCompounded += y;
        user.lastWith = block.timestamp;  
        user.keyCounter++;
        user.activeStakesCount++;
        compounds++;

	    emit Reinvested(msg.sender, user.refBonus);
    }

    function withdraw() public isInitialized returns (uint256 withdrawAmount) {
        User storage user = users[msg.sender];
        withdrawAmount = getUserDividends(msg.sender);
      
      	for (uint i = 0; i < user.depoList.length; i++){
          if (!user.depoList[i].initialWithdrawn) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        ovrTotalWiths += withdrawAmount;
        user.totalWithdrawn += withdrawAmount;
        user.lastWith = block.timestamp;

        BUSD.transfer(msg.sender, withdrawAmount);

		emit Withdrawn(msg.sender, withdrawAmount);
    }
  
    function withdrawInitial(uint256 key) public isInitialized {
        User storage user = users[msg.sender];

        if (user.depoList[key].initialWithdrawn) revert("This user stake is already forfeited.");  
        
        uint256 dailyReturn;
        uint256 refundAmount;
        uint256 amount = user.depoList[key].amt;
        uint256 elapsedTime = block.timestamp.sub(user.depoList[key].depoTime);
        
        if (elapsedTime <= PercsKey[10].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[10].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[10].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[10].daysInSeconds && elapsedTime <= PercsKey[20].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[20].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[20].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[30].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[30].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[40].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[40].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[50].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[50].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[60].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[60].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[60].feePercentage).div(percentDivider));
        } else {
            revert("Cannot calculate user's staked days.");
        }

        BUSD.transfer(msg.sender, refundAmount);
        user.activeStakesCount--;
        user.totalInvested -= amount;
        user.depoList[key].amt = 0;
        user.depoList[key].initialWithdrawn = true;
        user.depoList[key].depoTime = block.timestamp;
        
		emit WithdrawnInitial(msg.sender, refundAmount);
    }

    function getUserDividends(address addr) public view returns (uint256) {
        User storage user = users[addr];
        uint256 totalWithdrawable;     
        for (uint256 i = 0; i < user.depoList.length; i++){	
            uint256 elapsedTime = block.timestamp.sub(user.depoList[i].depoTime);
            uint256 amount = user.depoList[i].amt;
            if (user.depoList[i].initialWithdrawn) continue;

            if (elapsedTime <= PercsKey[10].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[10].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[10].daysInSeconds && elapsedTime <= PercsKey[20].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[20].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[30].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[40].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[50].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[60].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[60].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
        }
        return totalWithdrawable;
    }
    
    function getUserAmountOfDeposits(address addr) view external returns(uint256) {
		return users[addr].depoList.length;
	}
    
    function getUserTotalDeposits(address addr) view external returns(uint256 amount) {
		for (uint256 i = 0; i < users[addr].depoList.length; i++) {
			amount = amount.add(users[addr].depoList[i].amt);
		}
	}

    function getUserDepositInfo(address userAddress, uint256 index) view external returns(uint256 depoKey, uint256 depositTime, uint256 amount, bool withdrawn) {
        depoKey = users[userAddress].depoList[index].key;
        depositTime = users[userAddress].depoList[index].depoTime;
		amount = users[userAddress].depoList[index].amt;
		withdrawn = users[userAddress].depoList[index].initialWithdrawn;
	}

    function getContractInfo() view external returns(uint256 totalUsers, uint256 launched, uint256 userCompounds, uint256 totalDeposited, uint256 totalCompounded, uint256 totalWithdrawn) {
		totalUsers = usersTotal;
        launched = dateLaunched;
		userCompounds = compounds;
		totalDeposited = ovrTotalDeps;
		totalCompounded = ovrTotalComp;
		totalWithdrawn = ovrTotalWiths;
	}
    
    function lastDepositInfo() view external returns(uint256 currentRound, uint256 currentBalance, uint256 currentStartTime, uint256 currentStep, address currentPotentialWinner, uint256 previousReward, address previousWinner) {
        currentRound = lastBuyCurrentRound;
        currentBalance = lastDepositPoolBalance;
        currentStartTime = lastDepositLastDrawAction;  
        currentStep = lastDepositTimeStep;    
        currentPotentialWinner = lastDepositPotentialWinner;
        previousReward = previousPoolRewards;
        previousWinner = previousPoolWinner;
    }

    function getUserInfo(address userAddress) view external returns(uint256 totalInvested, uint256 totalCompounded, uint256 totalWithdrawn, uint256 totalBonus, uint256 totalActiveStakes, uint256 totalStakesMade) {
		totalInvested = users[userAddress].totalInvested;
        totalCompounded = users[userAddress].totalCompounded;
        totalWithdrawn = users[userAddress].totalWithdrawn;
        totalBonus = users[userAddress].refBonus;
        totalActiveStakes = users[userAddress].activeStakesCount;
        totalStakesMade = users[userAddress].keyCounter;
	}

    function getBalance() view external returns(uint256){
         return BUSD.balanceOf(address(this));
    }
    
    function switchLastDepositEventStatus() external onlyOwner {
        drawLastDepositWinner();
        lastDepositEnabled = !lastDepositEnabled ? true : false;
        if(lastDepositEnabled) lastDepositLastDrawAction = block.timestamp; // reset the start time everytime feature is enabled.
    }
}