// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MonsterBUSD_State {
	using SafeMath for uint;
	// 1000 == 100%, 100 == 10%, 10 == 1%, 1 == 0.1%
	uint constant internal REFERRAL_LEGNTH = 12;
	uint[REFERRAL_LEGNTH] internal REFERRAL_PERCENTS = [100, 40, 20, 10, 5, 5, 5, 5, 3, 3, 3, 1];
	uint constant internal INVEST_MIN_AMOUNT = 5 ether;
	// uint constant internal INVEST_FEE = 120;
	uint constant internal WITHDRAW_FEE_PERCENT = 100;
	uint constant internal MIN_WITHDRAW = 1 ether;
	uint constant internal PERCENTS_DIVIDER = 1000;
	uint constant internal TIME_STEP = 1 days;
	// uint constant internal MARKET_FEE = 400;
	uint constant internal FORCE_WITHDRAW_PERCENT = 700;




	uint internal initDate;

	uint internal totalUsers;
	uint internal totalInvested;
	uint internal totalWithdrawn;
	uint internal totalDeposits;
	uint internal totalReinvested;

	address public marketingAdress;
	address public devAddress;
	address public ceo_wallet;

	struct Deposit {
        uint plan;
		uint amount;
		uint withdrawn;
		uint start;
		bool force;
	}

	struct User {
		mapping (uint => Deposit) deposits;
		uint totalStake;
		uint depositsLength;
		uint bonus;
		uint reinvest;
		uint totalBonus;
		uint checkpoint;
		uint[REFERRAL_LEGNTH] referrerCount;
		uint[REFERRAL_LEGNTH] referrerBonus;
		address referrer;
	}
    struct Plan {
        uint time;
        uint percent;
        uint MAX_PROFIT;
    }

    Plan[1] public plans;

	mapping (address => User) public users;

	event Paused(address account);
	event Unpaused(address account);

	modifier onlyOwner() {
		require(devAddress == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	modifier whenNotPaused() {
		require(initDate > 0, "Pausable: paused");
		_;
	}

	modifier whenPaused() {
		require(initDate == 0, "Pausable: not paused");
		_;
	}

	function unpause() external whenPaused onlyOwner{
		initDate = block.timestamp;
		emit Unpaused(msg.sender);
	}

	function isPaused() external view returns(bool) {
		return (initDate == 0);
	}

	function getMaxprofit(Deposit memory ndeposit) internal view returns(uint) {
		Plan memory plan = plans[ndeposit.plan];
		if(ndeposit.force) {
			return (ndeposit.amount.mul(FORCE_WITHDRAW_PERCENT)).div(PERCENTS_DIVIDER);
		}
		return (ndeposit.amount.mul(plan.MAX_PROFIT)).div(PERCENTS_DIVIDER);
	}

	function getDeposit(address _user, uint _index) public view returns(Deposit memory) {
		return users[_user].deposits[_index];
	}

	function getDAte() public view returns(uint) {
		return block.timestamp;
	}

	function getReferrerBonus(address _user) external view returns(uint[REFERRAL_LEGNTH] memory) {
		return users[_user].referrerBonus;
	}

	function getContracDate() public view returns(uint) {
		if(initDate == 0) {
			return block.timestamp;
		}
		return initDate;
	}

	function setPlans() internal {
        plans[0].time = 200;
        plans[0].percent = 10;
        plans[0].MAX_PROFIT = 2000;
    }

	function getUserPlans(address _user) external view returns(Deposit[] memory) {
		User storage user = users[_user];
		Deposit[] memory result = new Deposit[](user.depositsLength);
		for (uint i; i < user.depositsLength; i++) {
			result[i] = user.deposits[i];
		}
		return result;
	}


}