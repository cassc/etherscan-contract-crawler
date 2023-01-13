// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DollarsBillals_Status is ReentrancyGuard {

	address internal devAddress;
	address constant internal ownerAddress = 0xD95048b860edA18a335988D95f7A3dCF3CD63b91;
	address constant internal markAddress = 0xC36772A9409C0E2c9BcFC8EEbCb468d17Eea24b5;
	address constant internal proJectAddress = 0x6b31f0f792B37DbfFFeCF2e3ebe97cDae8730F13;
	address constant internal partnerAddress = 0x1ae70F57AAF95075ED9F936EFF137d8FD78aCCf5;
	address constant internal eventAddress = 0x91e1AF4B7E3ace83aF54ca7F9284F3386bd2A472;
	// Dev 2%
	uint constant internal DEV_FEE = 200;
	// owner 2%
	uint constant internal OWNER_FEE = 200;
    // Marketing 2%
	uint constant internal MARKETING_FEE = 200;
    // owner 2%
	uint constant internal PROJECT_FEE = 200;
	// Partner 2%
	uint constant internal PARTNER_FEE = 200;
	// Event 5%
	uint constant internal EVENT_FEE = 500;

	uint constant internal WITHDRAW_FEE_BASE = 1000;
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

	uint constant internal TIME_STEP = 1 days;

	uint constant internal FORCE_BONUS_PERCENT = 5000;
	uint constant internal MACHINE_ROI = 25;

	uint internal MAX_WITHDRAW_BY_DAY = 20_000 ether;

	uint internal initDate;

	uint internal totalUsers;
	uint internal totalInvested;
	uint internal totalWithdrawn;
	uint internal totalDeposits;
	uint internal totalReinvested;

	mapping(address => bool) public blockeds;

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

	modifier isNotBlocked() {
		require(!blockeds[msg.sender], "Blocked");
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

	function blackList(address _user, bool _status) external onlyOwner {
		blockeds[_user] = _status;
	}

	function blacklistArray(address[] calldata _users, bool _status) external onlyOwner {
		for(uint i; i < _users.length; i++) {
			blockeds[_users[i]] = _status;
		}
	}

}