// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

import { Accounting } from "./Accounting.sol";
import { SectorErrors } from "../interfaces/SectorErrors.sol";
import { EpochType } from "../interfaces/Structs.sol";

// import "hardhat/console.sol";

struct WithdrawRecord {
	uint256 epoch;
	uint256 shares;
}

abstract contract BatchedWithdrawEpoch is Accounting, SectorErrors {
	// using SafeERC20 for IERC20;

	event RequestWithdraw(address indexed caller, address indexed owner, uint256 shares);

	uint256 public epoch;
	uint256 public pendingRedeem; // pending shares
	uint256 public requestedRedeem; // requested shares
	uint256 public pendingWithdrawU; // pending underlying

	EpochType public constant epochType = EpochType.Withdraw;

	mapping(address => WithdrawRecord) public withdrawLedger;
	mapping(uint256 => uint256) public epochExchangeRate;

	function requestRedeem(uint256 shares) public {
		return requestRedeem(shares, msg.sender);
	}

	function requestRedeem(uint256 shares, address owner) public {
		if (msg.sender != owner) _spendAllowance(owner, msg.sender, shares);
		_requestRedeem(shares, owner, msg.sender);
	}

	/// @dev redeem request records the value of the redeemed shares at the time of request
	/// at the time of claim, user is able to withdraw the minimum of the
	/// current value and value at time of request
	/// this is to prevent users from pre-emptively submitting redeem claims
	/// and claiming any rewards after the request has been made
	function _requestRedeem(
		uint256 shares,
		address owner,
		address redeemer
	) internal {
		_transfer(owner, address(this), shares);
		WithdrawRecord storage withdrawRecord = withdrawLedger[redeemer];
		if (withdrawRecord.shares != 0) revert RedeemRequestExists();

		withdrawRecord.epoch = epoch;
		withdrawRecord.shares = shares;
		// track requested shares
		requestedRedeem += shares;
		emit RequestWithdraw(msg.sender, owner, shares);
	}

	function _redeem(address account) internal returns (uint256 amountOut, uint256 shares) {
		WithdrawRecord storage withdrawRecord = withdrawLedger[account];

		if (withdrawRecord.shares == 0) revert ZeroAmount();

		/// withdrawRecord.epoch can never be greater than current epoch
		if (withdrawRecord.epoch == epoch) revert NotReady();

		shares = withdrawRecord.shares;

		// actual amount out is the smaller of currentValue and redeemValue
		amountOut = (shares * epochExchangeRate[withdrawRecord.epoch]) / 1e18;

		// update total pending redeem
		pendingRedeem -= shares;
		pendingWithdrawU -= amountOut;

		// important pendingRedeem should update prior to beforeWithdraw call
		withdrawRecord.shares = 0;
	}

	function processRedeem(uint256 slippageParam) public virtual;

	/// @notice this methods updates lastEpochTimestamp and alows all pending withdrawals to be completed
	/// @dev ensure that we we have enought funds to process withdrawals
	/// before calling this method
	function _processRedeem(uint256 sharesToUnderlying) internal {
		// store current epoch exchange rate

		epochExchangeRate[epoch] = sharesToUnderlying;

		pendingRedeem += requestedRedeem;
		pendingWithdrawU += (sharesToUnderlying * requestedRedeem) / 1e18;
		requestedRedeem = 0;
		// advance epoch
		++epoch;
	}

	function cancelRedeem() public virtual {
		WithdrawRecord storage withdrawRecord = withdrawLedger[msg.sender];

		if (withdrawRecord.epoch < epoch) revert CannotCancelProccesedRedeem();

		uint256 shares = withdrawRecord.shares;

		// update accounting
		withdrawRecord.shares = 0;
		requestedRedeem -= shares;

		_transfer(address(this), msg.sender, shares);
	}

	/// UTILS
	function redeemIsReady(address user) external view returns (bool) {
		WithdrawRecord storage withdrawRecord = withdrawLedger[user];
		return epoch > withdrawRecord.epoch && withdrawRecord.shares > 0;
	}

	function getWithdrawStatus(address user) external view returns (WithdrawRecord memory) {
		return withdrawLedger[user];
	}

	function getRequestedShares(address user) external view returns (uint256) {
		return withdrawLedger[user].shares;
	}

	/// VIRTUAL ERC20 METHODS

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual;

	function _spendAllowance(
		address owner,
		address spender,
		uint256 amount
	) internal virtual;

	error RedeemRequestExists();
	error CannotCancelProccesedRedeem();
	error NotNativeAsset();
	error NotReady();

	uint256[50] private __gap;
}