// SPDX-License-Identifier: MIT
// solhint-disable max-states-count

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IStaking.sol";
import "../interfaces/IManager.sol";
import "../acctoke/interfaces/IAccToke.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { SafeMathUpgradeable as SafeMath } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { MathUpgradeable as Math } from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable as Ownable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { EnumerableSetUpgradeable as EnumerableSet } from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import { PausableUpgradeable as Pausable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable as ReentrancyGuard } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../interfaces/events/Destinations.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";
import "../interfaces/IDelegateFunction.sol";
import "../interfaces/events/IEventSender.sol";

contract Staking is IStaking, Initializable, Ownable, Pausable, ReentrancyGuard, IEventSender {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using EnumerableSet for EnumerableSet.UintSet;

	IERC20 public tokeToken;
	IManager public manager;

	address public treasury;

	uint256 public withheldLiquidity; // DEPRECATED
	//userAddress -> withdrawalInfo
	mapping(address => WithdrawalInfo) public requestedWithdrawals; // DEPRECATED

	//userAddress -> -> scheduleIndex -> staking detail
	mapping(address => mapping(uint256 => StakingDetails)) public userStakings;

	//userAddress -> scheduleIdx[]
	mapping(address => uint256[]) public userStakingSchedules;

	// We originally had the ability to remove schedules.
	// Reason for the extra tracking here around schedules

	//Schedule id/index counter
	uint256 public nextScheduleIndex;
	//scheduleIndex/id -> schedule
	mapping(uint256 => StakingSchedule) public schedules;
	//scheduleIndex/id[]
	EnumerableSet.UintSet private scheduleIdxs;

	//Can deposit into a non-public schedule
	mapping(address => bool) public override permissionedDepositors;

	bool public _eventSend;
	Destinations public destinations;

	IDelegateFunction public delegateFunction; //DEPRECATED

	// ScheduleIdx => notional address
	mapping(uint256 => address) public notionalAddresses;
	// address -> scheduleIdx -> WithdrawalInfo
	mapping(address => mapping(uint256 => WithdrawalInfo)) public withdrawalRequestsByIndex;

	address public override transferApprover;

	mapping(address => mapping(uint256 => QueuedTransfer)) public queuedTransfers;

	address public accToke;

	modifier onlyPermissionedDepositors() {
		require(_isAllowedPermissionedDeposit(), "CALLER_NOT_PERMISSIONED");
		_;
	}

	modifier onEventSend() {
		if (_eventSend) {
			_;
		}
	}

	//@custom:oz-upgrades-unsafe-allow constructor
	//solhint-disable-next-line no-empty-blocks
	constructor() public initializer {}

	function initialize(
		IERC20 _tokeToken,
		IManager _manager,
		address _treasury,
		address _scheduleZeroNotional
	) public initializer {
		__Context_init_unchained();
		__Ownable_init_unchained();
		__Pausable_init_unchained();

		require(address(_tokeToken) != address(0), "INVALID_TOKETOKEN");
		require(address(_manager) != address(0), "INVALID_MANAGER");
		require(_treasury != address(0), "INVALID_TREASURY");

		tokeToken = _tokeToken;
		manager = _manager;
		treasury = _treasury;

		//We want to be sure the schedule used for LP staking is first
		//because the order in which withdraws happen need to start with LP stakes
		_addSchedule(
			StakingSchedule({
				cliff: 0,
				duration: 1,
				interval: 1,
				setup: true,
				isActive: true,
				hardStart: 0,
				isPublic: true
			}),
			_scheduleZeroNotional
		);
	}

	function renounceOwnership() public override onlyOwner {
		revert("RENOUNCING_DISABLED");
	}

	function addSchedule(StakingSchedule memory schedule, address notional) external override onlyOwner {
		_addSchedule(schedule, notional);
	}

	function setPermissionedDepositor(address account, bool canDeposit) external override onlyOwner {
		permissionedDepositors[account] = canDeposit;

		emit PermissionedDepositorSet(account, canDeposit);
	}

	function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs) external override onlyOwner {
		uint256 userScheduleLength = userSchedulesIdxs.length;
		for (uint256 i = 0; i < userScheduleLength; ++i) {
			require(scheduleIdxs.contains(userSchedulesIdxs[i]), "INVALID_SCHEDULE");
		}

		userStakingSchedules[account] = userSchedulesIdxs;

		emit UserSchedulesSet(account, userSchedulesIdxs);
	}

	function getSchedules() external view override returns (StakingScheduleInfo[] memory retSchedules) {
		uint256 length = scheduleIdxs.length();
		retSchedules = new StakingScheduleInfo[](length);
		for (uint256 i = 0; i < length; ++i) {
			retSchedules[i] = StakingScheduleInfo(schedules[scheduleIdxs.at(i)], scheduleIdxs.at(i));
		}
	}

	function getStakes(address account) external view override returns (StakingDetails[] memory stakes) {
		stakes = _getStakes(account);
	}

	function setNotionalAddresses(
		uint256[] calldata scheduleIdxArr,
		address[] calldata addresses
	) external override onlyOwner {
		uint256 length = scheduleIdxArr.length;
		require(length == addresses.length, "MISMATCH_LENGTH");
		for (uint256 i = 0; i < length; ++i) {
			uint256 currentScheduleIdx = scheduleIdxArr[i];
			address currentAddress = addresses[i];
			require(scheduleIdxs.contains(currentScheduleIdx), "INDEX_DOESNT_EXIST");
			require(currentAddress != address(0), "INVALID_ADDRESS");

			notionalAddresses[currentScheduleIdx] = currentAddress;
		}
		emit NotionalAddressesSet(scheduleIdxArr, addresses);
	}

	function balanceOf(address account) public view override returns (uint256 value) {
		value = 0;
		uint256 length = userStakingSchedules[account].length;
		for (uint256 i = 0; i < length; ++i) {
			StakingDetails memory details = userStakings[account][userStakingSchedules[account][i]];
			uint256 remaining = details.initial.sub(details.withdrawn);
			if (remaining > details.slashed) {
				value = value.add(remaining.sub(details.slashed));
			}
		}
	}

	function sweepToScheduleZero(uint256 scheduleIdx, uint256 amount) external override whenNotPaused nonReentrant {
		require(amount > 0, "INVALID_AMOUNT");
		require(scheduleIdx != 0, "NOT_ZERO");
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_INDEX");

		StakingDetails storage stakeFrom = userStakings[msg.sender][scheduleIdx];
		uint256 amountAvailableToSweep = _vested(msg.sender, scheduleIdx).sub(stakeFrom.withdrawn);
		if (stakeFrom.slashed > 0) {
			if (stakeFrom.slashed > amountAvailableToSweep) {
				amountAvailableToSweep = 0;
			} else {
				amountAvailableToSweep = amountAvailableToSweep - stakeFrom.slashed; // Checked above, it'll be lte, no overflow risk
			}
		}

		require(amountAvailableToSweep >= amount, "INSUFFICIENT_BALANCE");

		StakingDetails storage stakeTo = userStakings[msg.sender][0];

		// Add 0 to userStakingSchedules
		if (stakeTo.started == 0) {
			userStakingSchedules[msg.sender].push(0);
			//solhint-disable-next-line not-rely-on-time
			stakeTo.started = block.timestamp;
		}
		stakeFrom.withdrawn = stakeFrom.withdrawn.add(amount);
		stakeTo.initial = stakeTo.initial.add(amount);

		uint256 remainingAmountWithdraw = stakeFrom.initial.sub((stakeFrom.withdrawn.add(stakeFrom.slashed)));

		if (withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount > remainingAmountWithdraw) {
			withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount = remainingAmountWithdraw;
		}

		uint256 voteAmountWithdraw = remainingAmountWithdraw
			.sub(withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount)
			.sub(queuedTransfers[msg.sender][scheduleIdx].amount);

		uint256 voteAmountDeposit = (stakeTo.initial.sub((stakeTo.withdrawn.add(stakeTo.slashed))))
			.sub(withdrawalRequestsByIndex[msg.sender][0].amount)
			.sub(queuedTransfers[msg.sender][0].amount);

		depositWithdrawEvent(msg.sender, voteAmountWithdraw, scheduleIdx, msg.sender, voteAmountDeposit, 0);

		emit ZeroSweep(msg.sender, amount, scheduleIdx);
	}

	function availableForWithdrawal(address account, uint256 scheduleIndex) external view override returns (uint256) {
		return _availableForWithdrawal(account, scheduleIndex);
	}

	function unvested(address account, uint256 scheduleIndex) external view override returns (uint256 value) {
		value = 0;
		StakingDetails memory stake = userStakings[account][scheduleIndex];

		value = stake.initial.sub(_vested(account, scheduleIndex));
	}

	function vested(address account, uint256 scheduleIndex) external view override returns (uint256 value) {
		return _vested(account, scheduleIndex);
	}

	function deposit(uint256 amount, uint256 scheduleIndex) external override {
		_depositFor(msg.sender, amount, scheduleIndex);
	}

	function deposit(uint256 amount) external override {
		_depositFor(msg.sender, amount, 0);
	}

	function depositFor(
		address account,
		uint256 amount,
		uint256 scheduleIndex
	) external override onlyPermissionedDepositors {
		_depositFor(account, amount, scheduleIndex);
	}

	function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external override {
		require(amount > 0, "INVALID_AMOUNT");
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");
		uint256 availableAmount = _availableForWithdrawal(msg.sender, scheduleIdx);
		require(availableAmount >= amount, "INSUFFICIENT_AVAILABLE");

		withdrawalRequestsByIndex[msg.sender][scheduleIdx].amount = amount;
		if (manager.getRolloverStatus()) {
			withdrawalRequestsByIndex[msg.sender][scheduleIdx].minCycleIndex = manager.getCurrentCycleIndex().add(2);
		} else {
			withdrawalRequestsByIndex[msg.sender][scheduleIdx].minCycleIndex = manager.getCurrentCycleIndex().add(1);
		}

		bytes32 eventSig = "Withdrawal Request";
		StakingDetails memory userStake = userStakings[msg.sender][scheduleIdx];
		uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(amount).sub(
			queuedTransfers[msg.sender][scheduleIdx].amount
		);

		encodeAndSendData(eventSig, msg.sender, scheduleIdx, voteTotal);

		emit WithdrawalRequested(msg.sender, scheduleIdx, amount);
	}

	function withdraw(uint256 amount, uint256 scheduleIdx) external override nonReentrant whenNotPaused {
		require(amount > 0, "NO_WITHDRAWAL");
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");
		_withdraw(amount, scheduleIdx);
	}

	function withdraw(uint256 amount) external override whenNotPaused nonReentrant {
		require(amount > 0, "INVALID_AMOUNT");
		_withdraw(amount, 0);
	}

	function withdrawAndMigrate(uint256 amount, uint256 numOfCycles) external override nonReentrant whenNotPaused {
		require(accToke != address(0), "ACC_TOKE_NOT_SET");
		require(amount > 0, "INVALID_AMOUNT");
		require(numOfCycles > 0, "INVALID_NB_CYCLES");

		uint256 scheduleIdx = 0;

		uint256 queuedTransfersAmount = queuedTransfers[msg.sender][scheduleIdx].amount;
		require(queuedTransfersAmount == 0, "CANT_HAVE_TRANSFER_QUEUED");

		uint256 availableToBeRequestedToBeWithdrawn = _availableForWithdrawal(msg.sender, scheduleIdx);
		require(availableToBeRequestedToBeWithdrawn >= amount, "INSUFFICIENT_AVAILABLE");

		WithdrawalInfo storage request = withdrawalRequestsByIndex[msg.sender][scheduleIdx];
		uint256 availableAmount = availableToBeRequestedToBeWithdrawn.sub(request.amount);

		if (availableAmount < amount) {
			// we need to take from withdrawalRequests too
			uint256 toRemoveFromWithdrawalRequests = amount.sub(availableAmount);
			request.amount = request.amount.sub(toRemoveFromWithdrawalRequests);

			if (request.amount == 0) {
				request.minCycleIndex = 0;
			}
		}

		StakingDetails storage userStake = userStakings[msg.sender][scheduleIdx];
		userStake.withdrawn = userStake.withdrawn.add(amount);

		tokeToken.safeIncreaseAllowance(accToke, amount);
		IAccToke(accToke).lockTokeFor(amount, numOfCycles, msg.sender);

		bytes32 eventSig = "Withdraw";

		uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(request.amount);

		encodeAndSendData(eventSig, msg.sender, scheduleIdx, voteTotal);

		emit Migrated(msg.sender, amount, scheduleIdx);
	}

	function slash(
		address[] calldata accounts,
		uint256[] calldata amounts,
		uint256 scheduleIndex
	) external override onlyOwner whenNotPaused {
		require(accounts.length == amounts.length, "LENGTH_MISMATCH");
		StakingSchedule storage schedule = schedules[scheduleIndex];
		require(schedule.setup, "INVALID_SCHEDULE");

		uint256 treasuryAmt = 0;

		for (uint256 i = 0; i < accounts.length; ++i) {
			address account = accounts[i];
			uint256 amount = amounts[i];

			require(amount > 0, "INVALID_AMOUNT");
			require(account != address(0), "INVALID_ADDRESS");

			StakingDetails memory userStake = userStakings[account][scheduleIndex];
			require(userStake.initial > 0, "NO_VESTING");

			uint256 availableToSlash = 0;
			uint256 remaining = userStake.initial.sub(userStake.withdrawn);
			if (remaining > userStake.slashed) {
				availableToSlash = remaining.sub(userStake.slashed);
			}

			require(availableToSlash >= amount, "INSUFFICIENT_AVAILABLE");

			userStake.slashed = userStake.slashed.add(amount);
			userStakings[account][scheduleIndex] = userStake;

			uint256 totalLeft = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn)));

			if (withdrawalRequestsByIndex[account][scheduleIndex].amount > totalLeft) {
				withdrawalRequestsByIndex[account][scheduleIndex].amount = totalLeft;
			}

			uint256 voteAmount = totalLeft.sub(withdrawalRequestsByIndex[account][scheduleIndex].amount);

			// voteAmount is now the current total they have voteable. If a transfer
			// is also queued, we need to be sure the queued amount is still valid
			uint256 queuedTransfer = queuedTransfers[account][scheduleIndex].amount;
			if (queuedTransfer > 0 && queuedTransfer > voteAmount) {
				queuedTransfer = voteAmount;
				if (queuedTransfer == 0) {
					_removeQueuedTransfer(account, scheduleIndex);
				} else {
					queuedTransfers[account][scheduleIndex].amount = queuedTransfer;
				}
			}

			// An amount queued for transfer cannot be voted with.
			voteAmount = voteAmount.sub(queuedTransfer);

			bytes32 eventSig = "Slash";

			encodeAndSendData(eventSig, account, scheduleIndex, voteAmount);

			treasuryAmt = treasuryAmt.add(amount);

			emit Slashed(account, amount, scheduleIndex);
		}

		tokeToken.safeTransfer(treasury, treasuryAmt);
	}

	function queueTransfer(
		uint256 scheduleIdxFrom,
		uint256 scheduleIdxTo,
		uint256 amount,
		address to
	) external override whenNotPaused {
		require(queuedTransfers[msg.sender][scheduleIdxFrom].amount == 0, "TRANSFER_QUEUED");

		uint256 minCycle;
		if (manager.getRolloverStatus()) {
			minCycle = manager.getCurrentCycleIndex().add(2);
		} else {
			minCycle = manager.getCurrentCycleIndex().add(1);
		}

		_validateStakeTransfer(msg.sender, scheduleIdxFrom, scheduleIdxTo, amount, to);

		queuedTransfers[msg.sender][scheduleIdxFrom] = QueuedTransfer({
			from: msg.sender,
			scheduleIdxFrom: scheduleIdxFrom,
			scheduleIdxTo: scheduleIdxTo,
			amount: amount,
			to: to,
			minCycle: minCycle
		});

		emit TransferQueued(msg.sender, scheduleIdxFrom, scheduleIdxTo, amount, to, minCycle);

		StakingDetails storage userStake = userStakings[msg.sender][scheduleIdxFrom];

		// Remove the queued transfer amounts from the user's vote total
		bytes32 eventSig = "Transfer";
		uint256 voteTotal = userStake
			.initial
			.sub((userStake.slashed.add(userStake.withdrawn)))
			.sub(withdrawalRequestsByIndex[msg.sender][scheduleIdxFrom].amount)
			.sub(amount);

		encodeAndSendData(eventSig, msg.sender, scheduleIdxFrom, voteTotal);
	}

	function removeQueuedTransfer(uint256 scheduleIdxFrom) external override whenNotPaused {
		_removeQueuedTransfer(msg.sender, scheduleIdxFrom);

		StakingDetails storage userStake = userStakings[msg.sender][scheduleIdxFrom];

		// Add the removed queued transfer amount to the user's vote total
		bytes32 eventSig = "Transfer";
		uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(
			withdrawalRequestsByIndex[msg.sender][scheduleIdxFrom].amount
		);

		encodeAndSendData(eventSig, msg.sender, scheduleIdxFrom, voteTotal);
	}

	function _removeQueuedTransfer(address account, uint256 scheduleIdxFrom) private {
		QueuedTransfer memory queuedTransfer = queuedTransfers[account][scheduleIdxFrom];
		delete queuedTransfers[account][scheduleIdxFrom];

		emit QueuedTransferRemoved(
			account,
			queuedTransfer.scheduleIdxFrom,
			queuedTransfer.scheduleIdxTo,
			queuedTransfer.amount,
			queuedTransfer.to,
			queuedTransfer.minCycle
		);
	}

	function rejectQueuedTransfer(address from, uint256 scheduleIdxFrom) external override whenNotPaused {
		require(msg.sender == transferApprover, "NOT_APPROVER");

		QueuedTransfer memory queuedTransfer = queuedTransfers[from][scheduleIdxFrom];
		require(queuedTransfer.amount != 0, "NO_TRANSFER_QUEUED");

		delete queuedTransfers[from][scheduleIdxFrom];

		emit QueuedTransferRejected(
			from,
			scheduleIdxFrom,
			queuedTransfer.scheduleIdxTo,
			queuedTransfer.amount,
			queuedTransfer.to,
			queuedTransfer.minCycle,
			msg.sender
		);

		StakingDetails storage userStake = userStakings[from][scheduleIdxFrom];

		// Add the rejected queued transfer amount to the user's vote total
		bytes32 eventSig = "Transfer";
		uint256 voteTotal = userStake.initial.sub((userStake.slashed.add(userStake.withdrawn))).sub(
			withdrawalRequestsByIndex[from][scheduleIdxFrom].amount
		);

		encodeAndSendData(eventSig, from, scheduleIdxFrom, voteTotal);
	}

	function setAccToke(address _accToke) external override onlyOwner {
		require(_accToke != address(0), "INVALID_ADDRESS");
		accToke = _accToke;
		emit AccTokeUpdated(accToke);
	}

	function approveQueuedTransfer(
		address from,
		uint256 scheduleIdxFrom,
		uint256 scheduleIdxTo,
		uint256 amount,
		address to
	) external override whenNotPaused nonReentrant {
		QueuedTransfer memory queuedTransfer = queuedTransfers[from][scheduleIdxFrom];

		require(msg.sender == transferApprover, "NOT_APPROVER");
		require(queuedTransfer.scheduleIdxTo == scheduleIdxTo, "MISMATCH_SCHEDULE_TO");
		require(queuedTransfer.amount == amount, "MISMATCH_AMOUNT");
		require(queuedTransfer.to == to, "MISMATCH_TO");
		require(manager.getCurrentCycleIndex() >= queuedTransfer.minCycle, "INVALID_CYCLE");

		delete queuedTransfers[from][scheduleIdxFrom];

		_validateStakeTransfer(from, scheduleIdxFrom, scheduleIdxTo, amount, to);

		StakingDetails storage stake = userStakings[from][scheduleIdxFrom];

		stake.initial = stake.initial.sub(amount);

		StakingDetails memory newStake = _updateStakingDetails(scheduleIdxTo, to, amount);

		uint256 voteAmountWithdraw = (stake.initial.sub((stake.withdrawn.add(stake.slashed)))).sub(
			withdrawalRequestsByIndex[from][scheduleIdxFrom].amount
		);

		uint256 voteAmountDeposit = (newStake.initial.sub((newStake.withdrawn.add(newStake.slashed))))
			.sub(withdrawalRequestsByIndex[to][scheduleIdxTo].amount)
			.sub(queuedTransfers[to][scheduleIdxTo].amount);

		depositWithdrawEvent(from, voteAmountWithdraw, scheduleIdxFrom, to, voteAmountDeposit, scheduleIdxTo);

		emit StakeTransferred(from, scheduleIdxFrom, scheduleIdxTo, amount, to);
	}

	function getQueuedTransfer(
		address fromAddress,
		uint256 fromScheduleId
	) external view override returns (QueuedTransfer memory) {
		return queuedTransfers[fromAddress][fromScheduleId];
	}

	function setScheduleStatus(uint256 scheduleId, bool activeBool) external override onlyOwner {
		require(scheduleIdxs.contains(scheduleId), "INVALID_SCHEDULE");

		StakingSchedule storage schedule = schedules[scheduleId];
		schedule.isActive = activeBool;

		emit ScheduleStatusSet(scheduleId, activeBool);
	}

	function setScheduleHardStart(uint256 scheduleIdx, uint256 hardStart) external override onlyOwner {
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");

		StakingSchedule storage schedule = schedules[scheduleIdx];

		require(schedule.hardStart > 0, "HARDSTART_NOT_SET");
		require(schedule.hardStart < hardStart, "HARDSTART_MUST_BE_GT");

		schedule.hardStart = hardStart;

		emit ScheduleHardStartSet(scheduleIdx, hardStart);
	}

	function updateScheduleStart(address[] calldata accounts, uint256 scheduleIdx) external override onlyOwner {
		require(scheduleIdxs.contains(scheduleIdx), "INVALID_SCHEDULE");

		uint256 hardStart = schedules[scheduleIdx].hardStart;
		require(hardStart > 0, "HARDSTART_NOT_SET");
		for (uint256 i = 0; i < accounts.length; ++i) {
			StakingDetails storage stake = userStakings[accounts[i]][scheduleIdx];
			require(stake.started != 0);
			stake.started = hardStart;
		}
	}

	function pause() external override onlyOwner {
		_pause();
	}

	function unpause() external override onlyOwner {
		_unpause();
	}

	function setDestinations(address _fxStateSender, address _destinationOnL2) external override onlyOwner {
		require(_fxStateSender != address(0), "INVALID_ADDRESS");
		require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

		destinations.fxStateSender = IFxStateSender(_fxStateSender);
		destinations.destinationOnL2 = _destinationOnL2;

		emit DestinationsSet(_fxStateSender, _destinationOnL2);
	}

	function setEventSend(bool _eventSendSet) external override onlyOwner {
		require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");

		_eventSend = _eventSendSet;

		emit EventSendSet(_eventSendSet);
	}

	function setTransferApprover(address approver) external override onlyOwner {
		require(approver != address(0), "INVALID_ADDRESS");
		transferApprover = approver;

		emit TransferApproverSet(approver);
	}

	function _availableForWithdrawal(address account, uint256 scheduleIndex) private view returns (uint256) {
		StakingDetails memory stake = userStakings[account][scheduleIndex];
		uint256 vestedWoWithdrawn = _vested(account, scheduleIndex).sub(stake.withdrawn);
		if (stake.slashed > vestedWoWithdrawn) {
			return 0;
		}
		uint256 woSlashed = vestedWoWithdrawn - stake.slashed; // Checked above, it'll be lte, no overflow risk

		// Transfer amounts can be for unvested amts so we need to handle carefully
		uint256 requestedTransfer = queuedTransfers[account][scheduleIndex].amount;
		if (requestedTransfer > woSlashed) {
			return 0;
		}
		return woSlashed - requestedTransfer; // Checked above, it'll be lte, no overflow risk
	}

	function _validateStakeTransfer(
		address from,
		uint256 scheduleIdxFrom,
		uint256 scheduleIdxTo,
		uint256 amount,
		address to
	) private {
		require(amount > 0, "INVALID_AMOUNT");
		require(to != address(0), "INVALID_ADDRESS");

		if (to == from) {
			require(scheduleIdxFrom != scheduleIdxTo, "NO_SELF_SAME_SCHEDULE");
		}

		StakingSchedule memory scheduleTo = schedules[scheduleIdxTo];

		if (scheduleIdxFrom != scheduleIdxTo) {
			require(scheduleTo.setup, "MUST_BE_SETUP");
			require(scheduleTo.isActive, "MUST_BE_ACTIVE");

			StakingSchedule memory scheduleFrom = schedules[scheduleIdxFrom];
			require(
				scheduleTo.hardStart.add(scheduleTo.cliff) >= scheduleFrom.hardStart.add(scheduleFrom.cliff),
				"CLIFF_MUST_BE_GTE"
			);
			require(
				scheduleTo.hardStart.add(scheduleTo.cliff).add(scheduleTo.duration) >=
					scheduleFrom.hardStart.add(scheduleFrom.cliff).add(scheduleFrom.duration),
				"SCHEDULE_MUST_BE_GTE"
			);
		}

		StakingDetails memory stake = userStakings[from][scheduleIdxFrom];
		require(
			amount <=
				stake.initial.sub((stake.withdrawn.add(stake.slashed))).sub(
					withdrawalRequestsByIndex[from][scheduleIdxFrom].amount
				),
			"INSUFFICIENT_AVAILABLE"
		);
	}

	function _depositFor(address account, uint256 amount, uint256 scheduleIndex) private nonReentrant whenNotPaused {
		StakingSchedule memory schedule = schedules[scheduleIndex];
		require(amount > 0, "INVALID_AMOUNT");
		require(schedule.setup, "INVALID_SCHEDULE");
		require(schedule.isActive, "INACTIVE_SCHEDULE");
		require(account != address(0), "INVALID_ADDRESS");
		require(schedule.isPublic || _isAllowedPermissionedDeposit(), "PERMISSIONED_SCHEDULE");

		StakingDetails memory userStake = _updateStakingDetails(scheduleIndex, account, amount);

		bytes32 eventSig = "Deposit";
		uint256 voteTotal = userStake
			.initial
			.sub((userStake.slashed.add(userStake.withdrawn)))
			.sub(withdrawalRequestsByIndex[account][scheduleIndex].amount)
			.sub(queuedTransfers[account][scheduleIndex].amount);

		encodeAndSendData(eventSig, account, scheduleIndex, voteTotal);

		tokeToken.safeTransferFrom(msg.sender, address(this), amount);

		emit Deposited(account, amount, scheduleIndex);
	}

	function _withdraw(uint256 amount, uint256 scheduleIdx) private {
		WithdrawalInfo storage request = withdrawalRequestsByIndex[msg.sender][scheduleIdx];
		require(amount <= request.amount, "INSUFFICIENT_AVAILABLE");
		require(request.minCycleIndex <= manager.getCurrentCycleIndex(), "INVALID_CYCLE");

		StakingDetails storage userStake = userStakings[msg.sender][scheduleIdx];
		userStake.withdrawn = userStake.withdrawn.add(amount);

		request.amount = request.amount.sub(amount);

		if (request.amount == 0) {
			request.minCycleIndex = 0;
		}

		tokeToken.safeTransfer(msg.sender, amount);

		emit WithdrawCompleted(msg.sender, scheduleIdx, amount);
	}

	function _vested(address account, uint256 scheduleIndex) private view returns (uint256) {
		// solhint-disable-next-line not-rely-on-time
		uint256 timestamp = block.timestamp;
		uint256 value = 0;
		StakingDetails memory stake = userStakings[account][scheduleIndex];
		StakingSchedule memory schedule = schedules[scheduleIndex];

		uint256 cliffTimestamp = stake.started.add(schedule.cliff);
		if (cliffTimestamp <= timestamp) {
			if (cliffTimestamp.add(schedule.duration) <= timestamp) {
				value = stake.initial;
			} else {
				uint256 secondsStaked = Math.max(timestamp.sub(cliffTimestamp), 1);
				//Precision loss is intentional. Enables the interval buckets
				uint256 effectiveSecondsStaked = (secondsStaked.div(schedule.interval)).mul(schedule.interval);
				value = stake.initial.mul(effectiveSecondsStaked).div(schedule.duration);
			}
		}

		return value;
	}

	function _addSchedule(StakingSchedule memory schedule, address notional) private {
		require(schedule.duration > 0, "INVALID_DURATION");
		require(schedule.interval > 0, "INVALID_INTERVAL");
		require(notional != address(0), "INVALID_ADDRESS");

		schedule.setup = true;
		uint256 index = nextScheduleIndex;
		require(scheduleIdxs.add(index), "ADD_FAIL");
		schedules[index] = schedule;
		notionalAddresses[index] = notional;
		nextScheduleIndex = nextScheduleIndex.add(1);

		emit ScheduleAdded(
			index,
			schedule.cliff,
			schedule.duration,
			schedule.interval,
			schedule.setup,
			schedule.isActive,
			schedule.hardStart,
			notional
		);
	}

	function _getStakes(address account) private view returns (StakingDetails[] memory stakes) {
		uint256 length = userStakingSchedules[account].length;
		stakes = new StakingDetails[](length);

		for (uint256 i = 0; i < length; ++i) {
			stakes[i] = userStakings[account][userStakingSchedules[account][i]];
		}
	}

	function _isAllowedPermissionedDeposit() private view returns (bool) {
		return permissionedDepositors[msg.sender] || msg.sender == owner();
	}

	function encodeAndSendData(
		bytes32 _eventSig,
		address _user,
		uint256 _scheduleIdx,
		uint256 _userBalance
	) private onEventSend {
		require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
		require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");
		address notionalAddress = notionalAddresses[_scheduleIdx];

		bytes memory data = abi.encode(
			BalanceUpdateEvent({ eventSig: _eventSig, account: _user, token: notionalAddress, amount: _userBalance })
		);

		destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
	}

	function _updateStakingDetails(
		uint256 scheduleIdx,
		address account,
		uint256 amount
	) private returns (StakingDetails memory) {
		StakingDetails storage stake = userStakings[account][scheduleIdx];
		if (stake.started == 0) {
			userStakingSchedules[account].push(scheduleIdx);
			uint256 hardStart = schedules[scheduleIdx].hardStart;
			if (hardStart > 0) {
				stake.started = hardStart;
			} else {
				//solhint-disable-next-line not-rely-on-time
				stake.started = block.timestamp;
			}
		}
		stake.initial = stake.initial.add(amount);
		stake.scheduleIx = scheduleIdx;

		return stake;
	}

	function depositWithdrawEvent(
		address withdrawUser,
		uint256 totalFromWithdrawAccount,
		uint256 withdrawScheduleIdx,
		address depositUser,
		uint256 totalFromDepositAccount,
		uint256 depositScheduleIdx
	) private {
		bytes32 withdrawEvent = "Withdraw";
		bytes32 depositEvent = "Deposit";
		encodeAndSendData(withdrawEvent, withdrawUser, withdrawScheduleIdx, totalFromWithdrawAccount);
		encodeAndSendData(depositEvent, depositUser, depositScheduleIdx, totalFromDepositAccount);
	}
}