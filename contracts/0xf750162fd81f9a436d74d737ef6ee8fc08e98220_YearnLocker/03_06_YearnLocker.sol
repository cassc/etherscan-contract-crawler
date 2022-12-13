// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVeYFI } from "../interfaces/IVeYFI.sol";
import { IRewardPool } from "../interfaces/IRewardPool.sol";

/// @title Yearn Locker
/// @author StakeDAO
/// @notice Locks the YFI tokens to veYFI contract
contract YearnLocker {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public yearnDepositor;
	address public accumulator;
	address public rewardPool;

	address public constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
	address public VEYFI;

	/* ========== EVENTS ========== */
	event LockCreated(address indexed user, uint256 value, uint256 duration);
	event TokenClaimed(address indexed user, uint256 value);
	event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
	event Released(address indexed user, uint256 value);
	event GovernanceChanged(address indexed newGovernance);
	event YFIDepositorChanged(address indexed newYearnDepositor);
	event AccumulatorChanged(address indexed newAccumulator);
	event RewardPoolChanged(address indexed newRewardPool);

	/* ========== CONSTRUCTOR ========== */
	constructor(
		address _governance,
		address _accumulator,
		address _veToken,
		address _rewardPool
	) {
		governance = _governance;
		accumulator = _accumulator;
		VEYFI = _veToken;
		rewardPool = _rewardPool;
	}

	/* ========== MODIFIERS ========== */
	modifier onlyGovernance() {
		require(msg.sender == governance, "!gov");
		_;
	}

	modifier onlyGovernanceOrAcc() {
		require(msg.sender == governance || msg.sender == accumulator, "!(gov||acc)");
		_;
	}

	modifier onlyGovernanceOrDepositor() {
		require(msg.sender == governance || msg.sender == yearnDepositor, "!(gov||YearnDepositor)");
		_;
	}

	function approveUnderlying() external onlyGovernance {
		IERC20(YFI).approve(VEYFI, 0);
		IERC20(YFI).approve(VEYFI, type(uint256).max);
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Creates a lock by locking YFI token in the VotingYFI contract for the specified time
	/// @dev Can only be called by governance or proxy
	/// @param _value The amount of token to be locked
	/// @param _unlockTime The duration for which the token is to be locked
	function createLock(uint256 _value, uint256 _unlockTime) external onlyGovernance {
		IVeYFI(VEYFI).modify_lock(_value, _unlockTime, address(this));
		emit LockCreated(msg.sender, _value, _unlockTime);
	}

	/// @notice Increases the amount of YFI locked in veYFI
	/// @dev The YFI needs to be transferred to this contract before calling
	/// @param _value The amount by which the lock amount is to be increased
	function increaseAmount(uint256 _value) external onlyGovernanceOrDepositor {
		IVeYFI(VEYFI).modify_lock(_value, 0, address(this));
	}

	/// @notice Increases the duration for which YFI is locked in VotingYFI for the user calling the function
	/// @param _unlockTime The duration in seconds for which the token is to be locked
	function increaseUnlockTime(uint256 _unlockTime) external onlyGovernanceOrDepositor {
		IVeYFI(VEYFI).modify_lock(0, _unlockTime, address(this));
	}

	/// @notice Claim the token reward from the VotingYFI RewardPool passing the token as input parameter
	/// @param _recipient The address which will receive the claimed token reward
	function claimRewards(address _token, address _recipient) external onlyGovernanceOrAcc {
		uint256 claimed = IRewardPool(rewardPool).claim(address(this), false);
		emit TokenClaimed(_recipient, claimed);
		IERC20(_token).safeTransfer(_recipient, claimed);
	}

	/// @notice Withdraw the YFI from VotingYFI
	/// @dev call only after lock time expires
	/// @param _recipient The address which will receive the released YFI
	function release(address _recipient) external onlyGovernance {
		IVeYFI(VEYFI).withdraw();
		uint256 balance = IERC20(YFI).balanceOf(address(this));

		IERC20(YFI).safeTransfer(_recipient, balance);
		emit Released(_recipient, balance);
	}

	/// @notice Set new governance address
	/// @param _governance governance address
	function setGovernance(address _governance) external onlyGovernance {
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	/// @notice Set the YFI Depositor
	/// @param _yearnDepositor YFI deppositor address
	function setYFIDepositor(address _yearnDepositor) external onlyGovernance {
		yearnDepositor = _yearnDepositor;
		emit YFIDepositorChanged(_yearnDepositor);
	}

	/// @notice Set the Reward Pool
	/// @param _newRewardPool Reward Pool address
	function setRewardPool(address _newRewardPool) external onlyGovernance {
		rewardPool = _newRewardPool;
		emit RewardPoolChanged(_newRewardPool);
	}

	/// @notice Set the accumulator
	/// @param _accumulator accumulator address
	function setAccumulator(address _accumulator) external onlyGovernance {
		accumulator = _accumulator;
		emit AccumulatorChanged(_accumulator);
	}

	/// @notice execute a function
	/// @param to Address to sent the value to
	/// @param value Value to be sent
	/// @param data Call function data
	function execute(
		address to,
		uint256 value,
		bytes calldata data
	) external onlyGovernance returns (bool, bytes memory) {
		(bool success, bytes memory result) = to.call{ value: value }(data);
		return (success, result);
	}
}