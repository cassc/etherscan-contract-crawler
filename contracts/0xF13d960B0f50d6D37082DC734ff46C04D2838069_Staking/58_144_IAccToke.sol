// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9;

import "./IERC20NonTransferable.sol";

interface IAccToke is IERC20NonTransferable {
	struct WithdrawalInfo {
		uint256 minCycle;
		uint256 amount;
	}

	struct DepositInfo {
		uint256 lockCycle;
		uint256 lockDuration;
	}

	//////////////////////////
	// Events
	event TokeLockedEvent(
		address indexed tokeSource,
		address indexed account,
		uint256 numCycles,
		uint256 indexed currentCycle,
		uint256 amount
	);
	event WithdrawalRequestedEvent(address indexed account, uint256 amount);
	event WithdrawalRequestCancelledEvent(address indexed account);
	event WithdrawalEvent(address indexed account, uint256 amount);

	event MinLockCyclesSetEvent(uint256 minLockCycles);
	event MaxLockCyclesSetEvent(uint256 maxLockCycles);
	event MaxCapSetEvent(uint256 maxCap);

	//////////////////////////
	// Methods

	/// @notice Lock Toke for `numOfCycles` cycles -> get accToke
	/// @param tokeAmount Amount of TOKE to lock up
	/// @param numOfCycles Number of cycles to lock for
	function lockToke(uint256 tokeAmount, uint256 numOfCycles) external;

	/// @notice Lock Toke for a different account for `numOfCycles` cycles -> that account gets resulting accTOKE
	/// @param tokeAmount Amount of TOKE to lock up
	/// @param numOfCycles Number of cycles to lock for
	/// @param account Account to lock TOKE for
	function lockTokeFor(uint256 tokeAmount, uint256 numOfCycles, address account) external;

	/// @notice Request to withdraw TOKE from accToke
	/// @param amount Amount of accTOKE to return
	function requestWithdrawal(uint256 amount) external;

	/// @notice Cancel pending withdraw request (frees up accToke for rewards/voting)
	function cancelWithdrawalRequest() external;

	/// @notice Withdraw previously requested funds
	/// @param amount Amount of TOKE to withdraw
	function withdraw(uint256 amount) external;

	/// @return Amount of liquidity that should not be deployed for market making (this liquidity is set aside for completing requested withdrawals)
	function withheldLiquidity() external view returns (uint256);

	function minLockCycles() external view returns (uint256);

	function maxLockCycles() external view returns (uint256);

	function maxCap() external view returns (uint256);

	function setMaxCap(uint256 totalAmount) external;

	function setMaxLockCycles(uint256 _maxLockCycles) external;

	function setMinLockCycles(uint256 _minLockCycles) external;

	//////////////////////////////////////////////////
	//												//
	//			   	  Enumeration					//
	//												//
	//////////////////////////////////////////////////

	/// @notice Get current cycle
	function getCurrentCycleID() external view returns (uint256);

	/// @notice Get all the deposit information for a specified account
	/// @param account Account to get deposit info for
	/// @return lockCycle Cycle Index when deposit was made
	/// @return lockDuration Number of cycles deposit is locked for
	/// @return amount Amount of TOKE deposited
	function getDepositInfo(
		address account
	) external view returns (uint256 lockCycle, uint256 lockDuration, uint256 amount);

	/// @notice Get withdrawal request info for a specified account
	/// @param account User to get withdrawal request info for
	/// @return minCycle Minimum cycle ID when withdrawal can be processed
	/// @return amount Amount of TOKE requested for withdrawal
	function getWithdrawalInfo(address account) external view returns (uint256 minCycle, uint256 amount);
}