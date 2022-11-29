// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 *  @title Allows for the staking and vesting of TOKE for
 *  liquidity directors. Schedules can be added to enable various
 *  cliff+duration/interval unlock periods for vesting tokens.
 */
interface IStaking {
	struct StakingSchedule {
		uint256 cliff; // Duration in seconds before staking starts
		uint256 duration; // Seconds it takes for entire amount to stake
		uint256 interval; // Seconds it takes for a chunk to stake
		bool setup; //Just so we know its there
		bool isActive; //Whether we can setup new stakes with the schedule
		uint256 hardStart; //Stakings will always start at this timestamp if set
		bool isPublic; //Schedule can be written to by any account
	}

	struct StakingScheduleInfo {
		StakingSchedule schedule;
		uint256 index;
	}

	struct StakingDetails {
		uint256 initial; //Initial amount of asset when stake was created, total amount to be staked before slashing
		uint256 withdrawn; //Amount that was staked and subsequently withdrawn
		uint256 slashed; //Amount that has been slashed
		uint256 started; //Timestamp at which the stake started
		uint256 scheduleIx;
	}

	struct WithdrawalInfo {
		uint256 minCycleIndex;
		uint256 amount;
	}

	struct QueuedTransfer {
		address from;
		uint256 scheduleIdxFrom;
		uint256 scheduleIdxTo;
		uint256 amount;
		address to;
		uint256 minCycle;
	}

	event ScheduleAdded(
		uint256 scheduleIndex,
		uint256 cliff,
		uint256 duration,
		uint256 interval,
		bool setup,
		bool isActive,
		uint256 hardStart,
		address notional
	);
	event ScheduleRemoved(uint256 scheduleIndex);
	event WithdrawalRequested(address account, uint256 scheduleIdx, uint256 amount);
	event WithdrawCompleted(address account, uint256 scheduleIdx, uint256 amount);
	event Deposited(address account, uint256 amount, uint256 scheduleIx);
	event Slashed(address account, uint256 amount, uint256 scheduleIx);
	event PermissionedDepositorSet(address depositor, bool allowed);
	event UserSchedulesSet(address account, uint256[] userSchedulesIdxs);
	event NotionalAddressesSet(uint256[] scheduleIdxs, address[] addresses);
	event ScheduleStatusSet(uint256 scheduleId, bool isActive);
	event ScheduleHardStartSet(uint256 scheduleId, uint256 hardStart);
	event StakeTransferred(address from, uint256 scheduleFrom, uint256 scheduleTo, uint256 amount, address to);
	event ZeroSweep(address user, uint256 amount, uint256 scheduleFrom);
	event TransferApproverSet(address approverAddress);
	event TransferQueued(
		address from,
		uint256 scheduleFrom,
		uint256 scheduleTo,
		uint256 amount,
		address to,
		uint256 minCycle
	);
	event QueuedTransferRemoved(
		address from,
		uint256 scheduleFrom,
		uint256 scheduleTo,
		uint256 amount,
		address to,
		uint256 minCycle
	);
	event QueuedTransferRejected(
		address from,
		uint256 scheduleFrom,
		uint256 scheduleTo,
		uint256 amount,
		address to,
		uint256 minCycle,
		address rejectedBy
	);
	event Migrated(address from, uint256 amount, uint256 scheduleId);
	event AccTokeUpdated(address accToke);

	/// @notice Get a queued higher level schedule transfers
	/// @param fromAddress Account that initiated the transfer
	/// @param fromScheduleId Schedule they are transferring out of
	/// @return Details about the transfer
	function getQueuedTransfer(
		address fromAddress,
		uint256 fromScheduleId
	) external view returns (QueuedTransfer memory);

	/// @notice Get the current transfer approver
	/// @return Transfer approver address
	function transferApprover() external returns (address);

	///@notice Allows for checking of user address in permissionedDepositors mapping
	///@param account Address of account being checked
	///@return Boolean, true if address exists in mapping
	function permissionedDepositors(address account) external returns (bool);

	///@notice Allows owner to set a multitude of schedules that an address has access to
	///@param account User address
	///@param userSchedulesIdxs Array of schedule indexes
	function setUserSchedules(address account, uint256[] calldata userSchedulesIdxs) external;

	///@notice Allows owner to add schedule
	///@param schedule A StakingSchedule struct that contains all info needed to make a schedule
	///@param notional Notional addrss for schedule, used to send balances to L2 for voting purposes
	function addSchedule(StakingSchedule memory schedule, address notional) external;

	///@notice Gets all info on all schedules
	///@return retSchedules An array of StakingScheduleInfo struct
	function getSchedules() external view returns (StakingScheduleInfo[] memory retSchedules);

	///@notice Allows owner to set a permissioned depositor
	///@param account User address
	///@param canDeposit Boolean representing whether user can deposit
	function setPermissionedDepositor(address account, bool canDeposit) external;

	///@notice Allows a user to get the stakes of an account
	///@param account Address that is being checked for stakes
	///@return stakes StakingDetails array containing info about account's stakes
	function getStakes(address account) external view returns (StakingDetails[] memory stakes);

	///@notice Gets total value staked for an address across all schedules
	///@param account Address for which total stake is being calculated
	///@return value uint256 total of account
	function balanceOf(address account) external view returns (uint256 value);

	///@notice Returns amount available to withdraw for an account and schedule Index
	///@param account Address that is being checked for withdrawals
	///@param scheduleIndex Index of schedule that is being checked for withdrawals
	function availableForWithdrawal(address account, uint256 scheduleIndex) external view returns (uint256);

	///@notice Returns unvested amount for certain address and schedule index
	///@param account Address being checked for unvested amount
	///@param scheduleIndex Schedule index being checked for unvested amount
	///@return value Uint256 representing unvested amount
	function unvested(address account, uint256 scheduleIndex) external view returns (uint256 value);

	///@notice Returns vested amount for address and schedule index
	///@param account Address being checked for vested amount
	///@param scheduleIndex Schedule index being checked for vested amount
	///@return value Uint256 vested
	function vested(address account, uint256 scheduleIndex) external view returns (uint256 value);

	///@notice Allows user to deposit token to specific vesting / staking schedule
	///@param amount Uint256 amount to be deposited
	///@param scheduleIndex Uint256 representing schedule to user
	function deposit(uint256 amount, uint256 scheduleIndex) external;

	/// @notice Allows users to deposit into 0 schedule
	/// @param amount Deposit amount
	function deposit(uint256 amount) external;

	///@notice Allows account to deposit on behalf of other account
	///@param account Account to be deposited for
	///@param amount Amount to be deposited
	///@param scheduleIndex Index of schedule to be used for deposit
	function depositFor(address account, uint256 amount, uint256 scheduleIndex) external;

	///@notice User can request withdrawal from staking contract at end of cycle
	///@notice Performs checks to make sure amount <= amount available
	///@param amount Amount to withdraw
	///@param scheduleIdx Schedule index for withdrawal Request
	function requestWithdrawal(uint256 amount, uint256 scheduleIdx) external;

	///@notice Allows for withdrawal after successful withdraw request and proper amount of cycles passed
	///@param amount Amount to withdraw
	///@param scheduleIdx Schedule to withdraw from
	function withdraw(uint256 amount, uint256 scheduleIdx) external;

	///@notice Allows for withdrawal and migration to AccToke
	///@param amount Amount to withdraw
	///@param numOfCycles Number of cycles to lock for
	function withdrawAndMigrate(uint256 amount, uint256 numOfCycles) external;

	/// @notice Allows owner to set schedule to active or not
	/// @param scheduleIndex Schedule index to set isActive boolean
	/// @param activeBoolean Bool to set schedule active or not
	function setScheduleStatus(uint256 scheduleIndex, bool activeBoolean) external;

	/// @notice Allows owner to set the AccToke address
	/// @param _accToke Address of AccToke
	function setAccToke(address _accToke) external;

	/// @notice Allows owner to update schedule hard start
	/// @param scheduleIdx Schedule index to update
	/// @param hardStart new hardStart value
	function setScheduleHardStart(uint256 scheduleIdx, uint256 hardStart) external;

	/// @notice Allows owner to update users schedules start
	/// @param accounts Accounts to update
	/// @param scheduleIdx Schedule index to update
	function updateScheduleStart(address[] calldata accounts, uint256 scheduleIdx) external;

	/// @notice Pause deposits on the pool. Withdraws still allowed
	function pause() external;

	/// @notice Unpause deposits on the pool.
	function unpause() external;

	/// @notice Used to slash user funds when needed
	/// @notice accounts and amounts arrays must be same length
	/// @notice Only one scheduleIndex can be slashed at a time
	/// @dev Implementation must be restructed to owner account
	/// @param accounts Array of accounts to slash
	/// @param amounts Array of amounts that corresponds with accounts
	/// @param scheduleIndex scheduleIndex of users that are being slashed
	function slash(address[] calldata accounts, uint256[] calldata amounts, uint256 scheduleIndex) external;

	/// @notice Allows user to transfer stake to another address
	/// @param scheduleFrom, schedule stake being transferred from
	/// @param scheduleTo, schedule stake being transferred to
	/// @param amount, Amount to be transferred to new address and schedule
	/// @param to, Address to be transferred to
	function queueTransfer(uint256 scheduleFrom, uint256 scheduleTo, uint256 amount, address to) external;

	/// @notice Allows user to remove queued transfer
	/// @param scheduleIdxFrom scheduleIdx being transferred from
	function removeQueuedTransfer(uint256 scheduleIdxFrom) external;

	/// @notice Set the address used to denote the token amount for a particular schedule
	/// @dev Relates to the Balance Tracker tracking of tokens and balances. Each schedule is tracked separately
	function setNotionalAddresses(uint256[] calldata scheduleIdxArr, address[] calldata addresses) external;

	/// @notice For tokens in higher level schedules, move vested amounts to the default schedule
	/// @notice Allows for full voting weight to be applied when tokens have vested
	/// @param scheduleIdx Schedule to sweep tokens from
	/// @param amount Amount to sweep to default schedule
	function sweepToScheduleZero(uint256 scheduleIdx, uint256 amount) external;

	/// @notice Set the approver for higher schedule transfers
	/// @param approver New transfer approver
	function setTransferApprover(address approver) external;

	/// @notice Withdraw from the default schedule. Must have a request in previously
	/// @param amount Amount to withdraw
	function withdraw(uint256 amount) external;

	/// @notice Allows transfeApprover to reject a submitted transfer
	/// @param from address queued transfer is from
	/// @param scheduleIdxFrom Schedule index of queued transfer
	function rejectQueuedTransfer(address from, uint256 scheduleIdxFrom) external;

	/// @notice Approve a queued transfer from a higher level schedule
	/// @param from address that queued the transfer
	/// @param scheduleIdxFrom Schedule index of queued transfer
	/// @param scheduleIdxTo Schedule index of destination
	/// @param amount Amount being transferred
	/// @param to Destination account
	function approveQueuedTransfer(
		address from,
		uint256 scheduleIdxFrom,
		uint256 scheduleIdxTo,
		uint256 amount,
		address to
	) external;
}