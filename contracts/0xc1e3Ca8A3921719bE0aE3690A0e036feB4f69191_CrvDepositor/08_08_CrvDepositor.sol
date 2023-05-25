// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ITokenMinter.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/ISdToken.sol";
import "../interfaces/ILiquidityGauge.sol";


/// @title Contract that accepts tokens and locks them
/// @author StakeDAO
contract CrvDepositor {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */
	address public token;
	uint256 private constant MAXTIME = 4 * 364 * 86400;
	uint256 private constant WEEK = 7 * 86400;

	uint256 public lockIncentive = 10; //incentive to users who spend gas to lock token
	uint256 public constant FEE_DENOMINATOR = 10000;

	address public gauge;
	address public governance;
	address public immutable locker;
	address public immutable minter;
	uint256 public incentiveToken = 0;

	address public constant SD_VE_CRV = 0x478bBC744811eE8310B461514BDc29D03739084D;
	/* ========== EVENTS ========== */
	event Deposited(address indexed caller, address indexed user, uint256 amount, bool lock, bool stake);
	event IncentiveReceived(address indexed caller, uint256 amount);
	event TokenLocked(address indexed user, uint256 amount);
	event GovernanceChanged(address indexed newGovernance);
	event SdTokenOperatorChanged(address indexed newSdToken);
	event FeesChanged(uint256 newFee);

	/* ========== CONSTRUCTOR ========== */
	constructor(
		address _token,
		address _locker,
		address _minter
	) {
		governance = msg.sender;
		token = _token;
		locker = _locker;
		minter = _minter;
	}

	/* ========== RESTRICTED FUNCTIONS ========== */
	/// @notice Set the new governance
	/// @param _governance governance address
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "!auth");
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	/// @notice Set the new operator for minting sdToken
	/// @param _operator operator address
	function setSdTokenOperator(address _operator) external {
		require(msg.sender == governance, "!auth");
		ISdToken(minter).setOperator(_operator);
		emit SdTokenOperatorChanged(_operator);
	}

	/// @notice Set the gauge to deposit token yielded
	/// @param _gauge gauge address
	function setGauge(address _gauge) external {
		require(msg.sender == governance, "!auth");
		gauge = _gauge;
	}

	/// @notice set the fees for locking incentive
	/// @param _lockIncentive contract must have tokens to lock
	function setFees(uint256 _lockIncentive) external {
		require(msg.sender == governance, "!auth");

		if (_lockIncentive <= 30) {
			lockIncentive = _lockIncentive;
			emit FeesChanged(_lockIncentive);
		}
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	/// @notice Locks the tokens held by the contract
	/// @dev The contract must have tokens to lock
	function _lockToken() internal {
		uint256 tokenBalance = IERC20(token).balanceOf(address(this));

		// If there is Token available in the contract transfer it to the locker
		if (tokenBalance > 0) {
			IERC20(token).safeTransfer(locker, tokenBalance);
			emit TokenLocked(msg.sender, tokenBalance);
		}

		uint256 tokenBalanceStaker = IERC20(token).balanceOf(locker);
		// If the locker has no tokens then return
		if (tokenBalanceStaker == 0) {
			return;
		}

		ILocker(locker).increaseAmount(tokenBalanceStaker);
	}

	/// @notice Lock tokens held by the contract
	/// @dev The contract must have Token to lock
	function lockToken() external {
		_lockToken();

		// If there is incentive available give it to the user calling lockToken
		if (incentiveToken > 0) {
			ITokenMinter(minter).mint(msg.sender, incentiveToken);
			emit IncentiveReceived(msg.sender, incentiveToken);
			incentiveToken = 0;
		}
	}

	/// @notice Deposit & Lock Token
	/// @dev User needs to approve the contract to transfer the token
	/// @param _amount The amount of token to deposit
	/// @param _lock Whether to lock the token
	/// @param _stake Whether to stake the token
	/// @param _user User to deposit for
	function deposit(
		uint256 _amount,
		bool _lock,
		bool _stake,
		address _user
	) public {
		require(_amount > 0, "!>0");
		require(_user != address(0), "!user");

		// If User chooses to lock Token
		if (_lock) {
			IERC20(token).safeTransferFrom(msg.sender, locker, _amount);
			_lockToken();

			if (incentiveToken > 0) {
				_amount = _amount + incentiveToken;
				emit IncentiveReceived(msg.sender, incentiveToken);
				incentiveToken = 0;
			}
		} else {
			//move tokens here
			IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
			//defer lock cost to another user
			uint256 callIncentive = (_amount * lockIncentive) / FEE_DENOMINATOR;
			_amount = _amount - callIncentive;
			incentiveToken = incentiveToken + callIncentive;
		}

		if (_stake && gauge != address(0)) {
			ITokenMinter(minter).mint(address(this), _amount);
			IERC20(minter).safeIncreaseAllowance(gauge, _amount);
			ILiquidityGauge(gauge).deposit(_amount, _user);
		} else {
			ITokenMinter(minter).mint(_user, _amount);
		}

		emit Deposited(msg.sender, _user, _amount, _lock, _stake);
	}

	/// @notice Deposits all the token of a user & locks them based on the options choosen
	/// @dev User needs to approve the contract to transfer Token tokens
	/// @param _lock Whether to lock the token
	/// @param _stake Whether to stake the token
	/// @param _user User to deposit for
	function depositAll(
		bool _lock,
		bool _stake,
		address _user
	) external {
		uint256 tokenBal = IERC20(token).balanceOf(msg.sender);
		deposit(tokenBal, _lock, _stake, _user);
	}

	/// @notice Lock forever (irreversible action) old sdveCrv to sdCrv with 1:1 rate
	/// @dev User needs to approve the contract to transfer Token tokens
	/// @param _amount amount to lock
	function lockSdveCrvToSdCrv(uint256 _amount) external {
		IERC20(SD_VE_CRV).transferFrom(msg.sender, address(this), _amount);
		// mint new sdCrv to the user
		ITokenMinter(minter).mint(msg.sender, _amount);
	}
}