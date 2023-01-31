// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DollarsBillals_Status is ReentrancyGuard {

	address internal devAddress;
	address constant internal ownerAddress = 0x9050c4B8193452282722DD3EF7A4e07aF78f3B26;
	address constant internal markAddress = 0x6B83F7d4806b407AA186eb59f21480A8E76FebEA;
	address constant internal proJectAddress = 0x5D5A571f91582e82015a297839632F4Fa841CeD3;
	address constant internal partnerAddress = 0x7799D81769B91DFa7380ec58F6AD2527273503A6;
	address constant internal eventAddress = 0xc415e580C8228b7de825F1253FEFf5f9558435c2;
	// Dev 2%
	uint constant internal DEV_FEE = 100;
	// owner 2%
	uint constant internal OWNER_FEE = 100;
    // Marketing 2%
	uint constant internal MARKETING_FEE = 100;
    // owner 2%
	uint constant internal PROJECT_FEE = 100;
	// Partner 2%
	uint constant internal PARTNER_FEE = 100;
	// Event 5%
	uint constant internal EVENT_FEE = 500;

	uint constant internal WITHDRAW_FEE_BASE = 500;
	uint constant internal MAX_PROFIT = 20000;
	// 10000 = 100%, 1000 = 10%, 100 = 1%, 10 = 0.1%, 1 = 0.01%
	uint constant internal PERCENTS_DIVIDER = 10000;


	using SafeMath for uint;
	IERC20 public token; //0x55d398326f99059fF775485246999027B3197955 - usdt
	uint constant internal MACHINEBONUS_LENGTH = 20;
	uint[MACHINEBONUS_LENGTH] internal REFERRAL_PERCENTS = [4000, 2400, 1600, 600, 400, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 400, 600, 1600, 2400, 4000];
	uint constant internal INVEST_MIN_AMOUNT = 21 ether;
	uint constant internal MINIMAL_REINVEST_AMOUNT = 0.01 ether;
	uint constant internal ROI_BASE = 50;
	uint constant internal MIN_WITHDRAW = 1;
	// uint constant internal WITHDRAW_FEE_PERCENT = 50;
	uint constant internal WITHDRAW_FEE_PERCENT_DAY = 1000;
	uint constant internal WITHDRAW_FEE_PERCENT_WEEK = 700;
	uint constant internal WITHDRAW_FEE_PERCENT_TWO_WEEK = 300;
	uint constant internal WITHDRAW_FEE_PERCENT_MONTH = 0;

	uint constant public TIME_STEP = 1 days;
	uint constant internal WEEK_TO_DAY = 7;
	uint constant internal TIME_STEP_WEEK = TIME_STEP * WEEK_TO_DAY;

	uint constant internal FORCE_BONUS_PERCENT = 5000;
	uint constant internal MACHINE_ROI = 25;

	uint internal initDate;

	uint internal totalUsers;
	uint internal totalInvested;
	uint internal totalWithdrawn;
	uint internal totalDeposits;
	uint internal totalReinvested;


	uint internal constant MAX_WITHDRAW_PER_USER = 160_000 ether;
	uint internal constant MAX_WEEKLY_WITHDRAW_PER_USER = 40_000 ether;

	struct Deposit {
		uint amount;
		uint initAmount;
		uint withdrawn;
		uint start;
		bool isForceWithdraw;
	}

	struct MachineBonus {
		uint initAmount;
		uint withdrawn;
		uint start;
		uint level;
		uint bonus;
		uint lastPayBonus;
	}

	struct User {
		address userAddress;
		mapping (uint => Deposit) deposits;
		uint depositsLength;
		MachineBonus[MACHINEBONUS_LENGTH] machineDeposits;
		uint totalInvest;
		uint primeInvest;
		uint totalWithdraw;
		uint bonusWithdraw_c;
		uint reinvested;
		uint checkpoint;
		uint[MACHINEBONUS_LENGTH] referrerCount;
		uint totalBonus;
		address referrer;
		bool hasWithdraw_f;
		bool machineAllow;
	}

	mapping(address => User) public users;
	mapping (address => uint) public lastBlock;

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

	function getMaxprofit(Deposit memory ndeposit) internal pure returns(uint) {
		return (ndeposit.amount.mul(MAX_PROFIT)).div(PERCENTS_DIVIDER);
	}

	function getUserMaxProfit(address user) internal view returns(uint) {
		return users[user].primeInvest.mul(MAX_PROFIT).div(PERCENTS_DIVIDER);
	}

	function getUserTotalInvested(address user) internal view returns(uint) {
		return users[user].primeInvest;
	}

	function getDate() view external returns(uint) {
		return block.timestamp;
	}

	function getMachineDeposit(address user, uint index) external view returns(uint _initAmount, uint _withdrawn, uint _start) {
		_initAmount = users[user].machineDeposits[index].initAmount;
		_withdrawn = users[user].machineDeposits[index].withdrawn;
		_start = users[user].machineDeposits[index].start;
	}

	function getTotalMachineBonus(address _user) external view returns(uint) {
		uint totalMachineBonus;
		for(uint i; i < MACHINEBONUS_LENGTH; i++) {
			totalMachineBonus += users[_user].machineDeposits[i].initAmount;
		}
		return totalMachineBonus;
	}

	function getAlldeposits(address _user) external view returns(Deposit[] memory) {
		Deposit[] memory _deposits = new Deposit[](users[_user].depositsLength);
		for(uint i; i < users[_user].depositsLength; i++) {
			_deposits[i] = users[_user].deposits[i];
		}
		return _deposits;
	}

	function totalMachineWithdraw(address _user) external view returns(uint) {
		uint _totalMachineWithdraw;
		for(uint i; i < MACHINEBONUS_LENGTH; i++) {
			_totalMachineWithdraw += users[_user].machineDeposits[i].withdrawn;
		}
		return _totalMachineWithdraw;
	}

    function getlastActionDate(User storage user)
        internal
        view
        returns (uint)
    {
        uint checkpoint = user.checkpoint;

        if (initDate > checkpoint) checkpoint = initDate;

        return checkpoint;
    }

	function getMaxTimeWithdraw(uint userTimeStamp) public view returns(uint) {
		uint maxWithdraw = (MAX_WEEKLY_WITHDRAW_PER_USER * (block.timestamp.sub(userTimeStamp))) / (WEEK_TO_DAY * TIME_STEP);
		if(maxWithdraw > MAX_WITHDRAW_PER_USER) {
			maxWithdraw = MAX_WITHDRAW_PER_USER;
		}
		return maxWithdraw;
	}

	function getMaxTimeWithdrawByUser(address user) external view returns(uint _maxWithdraw, uint _maxWeek, uint _delta, uint _weekTime, uint _timeStep) {
		return (getMaxTimeWithdraw(getlastActionDate(users[user])), MAX_WEEKLY_WITHDRAW_PER_USER, block.timestamp.sub(getlastActionDate(users[user])), WEEK_TO_DAY, TIME_STEP);
	}

}