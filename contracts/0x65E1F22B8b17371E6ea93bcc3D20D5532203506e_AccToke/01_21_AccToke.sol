// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin4/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin4/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin4/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { PausableUpgradeable as Pausable } from "@openzeppelin4/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable as ReentrancyGuard } from "@openzeppelin4/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { AccessControlUpgradeable as AccessControl } from "@openzeppelin4/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/IManager.sol";
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/events/IEventSender.sol";

import "./IAccToke.sol";

contract AccToke is IAccToke, Initializable, Pausable, ReentrancyGuard, IEventSender, AccessControl {
	using SafeERC20 for IERC20;

	// wallet address -> deposit info for user (lock cycle / amount / lockedFor)
	mapping(address => DepositInfo) private _deposits;
	// wallet address -> accToke balance
	mapping(address => uint256) private _balances;
	// wallet address -> details of withdrawal request
	mapping(address => WithdrawalInfo) public requestedWithdrawals;

	// roles
	bytes32 public constant LOCK_FOR_ROLE = keccak256("LOCK_FOR_ROLE");

	IManager public manager;
	IERC20 public toke;
	uint256 public override minLockCycles;
	uint256 public override maxLockCycles;
	uint256 public override maxCap;

	uint256 internal accTotalSupply;

	// implied: deployableLiquidity = underlyer.balanceOf(this) - withheldLiquidity
	uint256 public override withheldLiquidity;

	//////////////////////////
	// L2 Sending Support
	bool public _eventSend;
	Destinations public destinations;
	bytes32 private constant EVENT_TYPE_DEPOSIT = bytes32("Deposit");
	bytes32 private constant EVENT_TYPE_WITHDRAW_REQUEST = bytes32("Withdrawal Request");

	modifier onEventSend() {
		if (_eventSend) {
			_;
		}
	}

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor() {
		_disableInitializers();
	}

	/// @param _manager Address of manager contract
	/// @param _minLockCycles Minimum number of lock cycles
	/// @param _maxLockCycles Maximum number of lock cycles
	/// @param _toke TOKE ERC20 address
	/// @param _maxCap Maximum amount of accToke that can be out there
	function initialize(
		address _manager,
		uint256 _minLockCycles,
		uint256 _maxLockCycles,
		IERC20 _toke,
		uint256 _maxCap
	) external initializer {
		require(_manager != address(0), "INVALID_MANAGER_ADDRESS");
		require(_minLockCycles > 0, "INVALID_MIN_LOCK_CYCLES");
		require(_maxLockCycles > 0, "INVALID_MAX_LOCK_CYCLES");
		require(_maxCap > 0, "INVALID_MAX_CAP");
		require(address(_toke) != address(0), "INVALID_TOKE_ADDRESS");

		__Context_init_unchained();
		__AccessControl_init_unchained();
		__Pausable_init_unchained();
		__ReentrancyGuard_init_unchained();

		// add deployer to default admin role
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(LOCK_FOR_ROLE, _msgSender());

		manager = IManager(_manager);
		toke = _toke;

		setMaxLockCycles(_maxLockCycles);
		setMinLockCycles(_minLockCycles);
		setMaxCap(_maxCap);
	}

	//////////////////////////////////////////////////
	//												//
	//					LOCKING						//
	//												//
	//////////////////////////////////////////////////

	function lockToke(uint256 tokeAmount, uint256 numOfCycles) external override whenNotPaused nonReentrant {
		_lockToke(msg.sender, tokeAmount, numOfCycles);
	}

	function lockTokeFor(
		uint256 tokeAmount,
		uint256 numOfCycles,
		address account
	) external override whenNotPaused nonReentrant onlyRole(LOCK_FOR_ROLE) {
		_lockToke(account, tokeAmount, numOfCycles);
	}

	/// @dev Private method that targets the lock to specific cycle
	/// @param account Account to lock TOKE for
	/// @param tokeAmount Amount of TOKE to lock up
	/// @param numOfCycles Number of cycles to lock for
	function _lockToke(address account, uint256 tokeAmount, uint256 numOfCycles) internal {
		require(account != address(0) && account != address(this), "INVALID_ACCOUNT");
		require(tokeAmount > 0, "INVALID_TOKE_AMOUNT");
		// check if there's sufficient TOKE to lock up
		require(toke.balanceOf(msg.sender) >= tokeAmount, "INSUFFICIENT_TOKE_BALANCE");
		// check if we're still under the cap
		require(maxCap >= accTotalSupply + tokeAmount, "MAX_CAP_EXCEEDED");

		// check if lock cycle info is valid
		_checkLockCyclesValidity(account, numOfCycles);

		// get current cycle ID (+1 if in rollover currently)
		uint256 currentCycleID = getCurrentCycleID();
		if (manager.getRolloverStatus()) currentCycleID++;

		// transfer toke to us
		toke.safeTransferFrom(msg.sender, address(this), tokeAmount);
		// update total supply
		accTotalSupply += tokeAmount;

		// update balance
		_balances[account] += tokeAmount;

		// save user's deposit info
		DepositInfo storage deposit = _deposits[account];
		deposit.lockDuration = numOfCycles;
		deposit.lockCycle = currentCycleID;

		// L1 event (deltas)
		emit TokeLockedEvent(msg.sender, account, numOfCycles, currentCycleID, tokeAmount);
		// L2 event (final balance)
		encodeAndSendData(EVENT_TYPE_DEPOSIT, account, _getUserVoteBalance(account));
	}

	//////////////////////////////////////////////////
	//												//
	//			Withdraw Requests					//
	//												//
	//////////////////////////////////////////////////

	function requestWithdrawal(uint256 amount) external override nonReentrant {
		// check amount and that there's something to withdraw to begin with
		require(amount > 0, "INVALID_AMOUNT");
		require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

		// check to make sure we can request withdrawal in this cycle to begin with
		_canRequestWithdrawalCheck();

		WithdrawalInfo storage withdrawalInfo = requestedWithdrawals[msg.sender];

		//adjust withheld liquidity by removing the original withheld amount and adding the new amount
		withheldLiquidity = withheldLiquidity - withdrawalInfo.amount + amount;

		withdrawalInfo.amount = amount;
		// set withdrawal cycle: if not rollover then current+1, otherwise current+2
		withdrawalInfo.minCycle = getCurrentCycleID() + (!manager.getRolloverStatus() ? 1 : 2);

		// L1 event (just a record of request)
		emit WithdrawalRequestedEvent(msg.sender, amount);
		// L2 (decrease voting balance)
		encodeAndSendData(EVENT_TYPE_WITHDRAW_REQUEST, msg.sender, _getUserVoteBalance(msg.sender));
	}

	function cancelWithdrawalRequest() external override nonReentrant {
		WithdrawalInfo storage withdrawalInfo = requestedWithdrawals[msg.sender];
		require(withdrawalInfo.amount > 0, "NO_PENDING_WITHDRAWAL_REQUESTS");

		//adjust withheld liquidity by removing this request's withdrawal amount
		withheldLiquidity -= withdrawalInfo.amount;

		delete requestedWithdrawals[msg.sender];

		// L1 signal
		emit WithdrawalRequestCancelledEvent(msg.sender);
		// L2 send increased voting balance
		encodeAndSendData(EVENT_TYPE_WITHDRAW_REQUEST, msg.sender, _getUserVoteBalance(msg.sender));
	}

	//////////////////////////////////////////////////
	//												//
	//					Withdrawal					//
	//												//
	//////////////////////////////////////////////////

	function withdraw(uint256 amount) external override whenNotPaused nonReentrant {
		require(amount > 0, "INVALID_AMOUNT");
		require(amount <= balanceOf(msg.sender), "INSUFFICIENT_BALANCE");

		uint256 allowance = _getMaxWithdrawalAmountAllowed();
		require(amount <= allowance, "AMOUNT_GT_MAX_WITHDRAWAL");

		// decrease withdrawal request
		WithdrawalInfo storage withdrawalInfo = requestedWithdrawals[msg.sender];
		withdrawalInfo.amount -= amount;

		// update balances
		_balances[msg.sender] -= amount;
		accTotalSupply -= amount;
		withheldLiquidity -= amount;

		// if no more balance, wipe out deposit info completely
		if (_balances[msg.sender] == 0) {
			delete _deposits[msg.sender];
		}

		// if request is exhausted, delete it
		if (withdrawalInfo.amount == 0) {
			delete requestedWithdrawals[msg.sender];
		}

		// send toke back to user
		toke.safeTransfer(msg.sender, amount);

		// L1 event
		emit WithdrawalEvent(msg.sender, amount);
		// L2 update: NOTE: not needed! since amount was already taken out when request was made
	}

	//////////////////////////////////////////////////
	//												//
	//			   IERC20 (partial)					//
	//												//
	//////////////////////////////////////////////////

	/// @dev See {IERC20-name}
	function name() external pure override returns (string memory) {
		return "accTOKE";
	}

	/// @dev See {IERC20-symbol}
	function symbol() external pure override returns (string memory) {
		return "accTOKE";
	}

	/// @dev See {IERC20-decimals}
	function decimals() external pure override returns (uint8) {
		return 18;
	}

	/// @dev See {IERC20-totalSupply}
	function totalSupply() external view override returns (uint256) {
		return accTotalSupply;
	}

	/// @dev See {IERC20-balanceOf}
	function balanceOf(address account) public view override returns (uint256 balance) {
		require(account != address(0), "INVALID_ADDRESS");
		return _balances[account];
	}

	//////////////////////////////////////////////////
	//												//
	//			   	  Enumeration					//
	//												//
	//////////////////////////////////////////////////

	/// @dev Presentable info from merged collections
	function getDepositInfo(
		address account
	) external view override returns (uint256 lockCycle, uint256 lockDuration, uint256 amount) {
		return (_deposits[account].lockCycle, _deposits[account].lockDuration, _balances[account]);
	}

	/// @dev added custom getter to avoid issues with directly returning struct
	function getWithdrawalInfo(address account) external view override returns (uint256 minCycle, uint256 amount) {
		return (requestedWithdrawals[account].minCycle, requestedWithdrawals[account].amount);
	}

	//////////////////////////////////////////////////////////
	//														//
	//			   Admin maintenance functions				//
	//														//
	//////////////////////////////////////////////////////////

	function setMinLockCycles(uint256 _minLockCycles) public override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_minLockCycles > 0 && _minLockCycles <= maxLockCycles, "INVALID_MIN_LOCK_CYCLES");
		minLockCycles = _minLockCycles;

		emit MinLockCyclesSetEvent(minLockCycles);
	}

	function setMaxLockCycles(uint256 _maxLockCycles) public override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_maxLockCycles >= minLockCycles, "INVALID_MAX_LOCK_CYCLES");
		maxLockCycles = _maxLockCycles;

		emit MaxLockCyclesSetEvent(maxLockCycles);
	}

	function setMaxCap(uint256 _maxCap) public override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_maxCap <= toke.totalSupply(), "LT_TOKE_SUPPLY");
		maxCap = _maxCap;

		emit MaxCapSetEvent(maxCap);
	}

	//////////////////////////////////////////////////
	//												//
	//		L2 Event Sending Functionality			//
	//												//
	//////////////////////////////////////////////////

	/// @dev Enable/Disable L2 event sending
	function setEventSend(bool _eventSendSet) external override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");

		_eventSend = _eventSendSet;

		emit EventSendSet(_eventSendSet);
	}

	/// @dev Set L2 destinations
	function setDestinations(
		address _fxStateSender,
		address _destinationOnL2
	) external override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(_fxStateSender != address(0), "INVALID_ADDRESS");
		require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

		destinations.fxStateSender = IFxStateSender(_fxStateSender);
		destinations.destinationOnL2 = _destinationOnL2;

		emit DestinationsSet(_fxStateSender, _destinationOnL2);
	}

	/// @dev Encode and send data to L2
	/// @param _eventSig Event signature: MUST be known and preset in routes prior (otherwise message is ignored)
	/// @param _user Address to send message about
	/// @param _amount Final balance snapshot we're sending
	function encodeAndSendData(bytes32 _eventSig, address _user, uint256 _amount) private onEventSend {
		require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
		require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

		bytes memory data = abi.encode(BalanceUpdateEvent(_eventSig, _user, address(this), _amount));

		destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
	}

	//////////////////////////////////////////////////
	//												//
	//			Misc Helper Functions				//
	//												//
	//////////////////////////////////////////////////

	function getCurrentCycleID() public view override returns (uint256) {
		return manager.getCurrentCycleIndex();
	}

	function _checkLockCyclesValidity(address account, uint256 lockForCycles) private view {
		// make sure the length of lock is valid
		require(lockForCycles >= minLockCycles && lockForCycles <= maxLockCycles, "INVALID_LOCK_CYCLES");
		// if the user has existing lock, make sure new duration is AT LEAST matching existing lock
		if (_deposits[account].lockDuration > 0) {
			require(lockForCycles >= _deposits[account].lockDuration, "LOCK_LENGTH_MUST_BE_GTE_EXISTING");
		}
	}

	function _canRequestWithdrawalCheck() internal view {
		uint256 currentCycleID = getCurrentCycleID();
		DepositInfo memory deposit = _deposits[msg.sender];
		// must be in correct cycle (past initial lock cycle, and when the lock expires)
		require(
			deposit.lockCycle < currentCycleID && // some time passed
				(currentCycleID - deposit.lockCycle) % deposit.lockDuration == 0, // next cycle after lock expiration
			"INVALID_CYCLE_FOR_WITHDRAWAL_REQUEST"
		);
	}

	/// @dev Check if a) can withdraw b) how much was requested
	function _getMaxWithdrawalAmountAllowed() internal view returns (uint256) {
		// get / check the withdrawal request
		WithdrawalInfo memory withdrawalInfo = requestedWithdrawals[msg.sender];
		require(withdrawalInfo.amount > 0, "NO_WITHDRAWAL_REQUEST");
		require(withdrawalInfo.minCycle <= getCurrentCycleID(), "WITHDRAWAL_NOT_YET_AVAILABLE");

		return withdrawalInfo.amount;
	}

	/// @dev Get user balance: acctoke amount - what's requested for withdraw
	function _getUserVoteBalance(address account) internal view returns (uint256) {
		return _balances[account] - requestedWithdrawals[account].amount;
	}
}