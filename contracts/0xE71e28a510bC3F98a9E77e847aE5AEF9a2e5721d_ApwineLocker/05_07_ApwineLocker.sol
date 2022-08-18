// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVeApw.sol";
import "./interfaces/IFeeDistributor.sol";

/// @title ApwLocker
/// @author StakeDAO
/// @notice Locks the APW tokens to veAPW contract
contract ApwineLocker {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public apwDepositor;
	address public accumulator;

	address public constant APW = 0x4104b135DBC9609Fc1A9490E61369036497660c8;
	address public constant VEAPW = 0xC5ca1EBF6e912E49A6a70Bb0385Ea065061a4F09;
	address public feeDistributor = 0x354743132e75E417344BcfDDed6a045140556414;

	/* ========== EVENTS ========== */
	event LockCreated(address indexed user, uint256 value, uint256 duration);
	event TokenClaimed(address indexed user, uint256 value);
	event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
	event Released(address indexed user, uint256 value);
	event GovernanceChanged(address indexed newGovernance);
	event APWDepositorChanged(address indexed newApwDepositor);
	event AccumulatorChanged(address indexed newAccumulator);
	event FeeDistributorChanged(address indexed newFeeDistributor);

	/* ========== CONSTRUCTOR ========== */
	constructor(address _accumulator) {
		governance = msg.sender;
		accumulator = _accumulator;
		IERC20(APW).approve(VEAPW, type(uint256).max);
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
		require(msg.sender == governance || msg.sender == apwDepositor, "!(gov||ApwineDepositor)");
		_;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Creates a lock by locking APW token in the veAPW contract for the specified time
	/// @dev Can only be called by governance or proxy
	/// @param _value The amount of token to be locked
	/// @param _unlockTime The duration for which the token is to be locked
	function createLock(uint256 _value, uint256 _unlockTime) external onlyGovernance {
		IVeApw(VEAPW).create_lock(_value, _unlockTime);
		emit LockCreated(msg.sender, _value, _unlockTime);
	}

	/// @notice Increases the amount of APW locked in veAPW
	/// @dev The APW needs to be transferred to this contract before calling
	/// @param _value The amount by which the lock amount is to be increased
	function increaseAmount(uint256 _value) external onlyGovernanceOrDepositor {
		IVeApw(VEAPW).increase_amount(_value);
	}

	/// @notice Increases the duration for which APW is locked in veAPW for the user calling the function
	/// @param _unlockTime The duration in seconds for which the token is to be locked
	function increaseUnlockTime(uint256 _unlockTime) external onlyGovernanceOrDepositor {
		IVeApw(VEAPW).increase_unlock_time(_unlockTime);
	}

	/// @notice Claim the token reward from the APW fee Distributor passing the token as input parameter
	/// @param _recipient The address which will receive the claimed token reward
	function claimRewards(address _token, address _recipient) external onlyGovernanceOrAcc {
		uint256 claimed = IFeeDistributor(feeDistributor).claim();
		emit TokenClaimed(_recipient, claimed);
		IERC20(_token).safeTransfer(_recipient, claimed);
	}

	/// @notice Withdraw the APW from veAPW
	/// @dev call only after lock time expires
	/// @param _recipient The address which will receive the released APW
	function release(address _recipient) external onlyGovernance {
		IVeApw(VEAPW).withdraw();
		uint256 balance = IERC20(APW).balanceOf(address(this));

		IERC20(APW).safeTransfer(_recipient, balance);
		emit Released(_recipient, balance);
	}

	/// @notice Set new governance address
	/// @param _governance governance address
	function setGovernance(address _governance) external onlyGovernance {
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	/// @notice Set the APW Depositor
	/// @param _apwDepositor apw deppositor address
	function setApwDepositor(address _apwDepositor) external onlyGovernance {
		apwDepositor = _apwDepositor;
		emit APWDepositorChanged(_apwDepositor);
	}

	/// @notice Set the fee distributor
	/// @param _newFD fee distributor address
	function setFeeDistributor(address _newFD) external onlyGovernance {
		feeDistributor = _newFD;
		emit FeeDistributorChanged(_newFD);
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