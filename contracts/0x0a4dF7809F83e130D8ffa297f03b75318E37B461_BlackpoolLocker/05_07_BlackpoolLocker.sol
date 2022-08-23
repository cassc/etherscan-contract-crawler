// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/VeToken.sol";
import "./interfaces/IFeeDistributor.sol";

/// @title Blackpool Locker
/// @author StakeDAO
/// @notice Locks the BPT tokens to veBPT contract
contract BlackpoolLocker {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public bptDepositor;
	address public accumulator;

	address public constant BPT = 0x0eC9F76202a7061eB9b3a7D6B59D36215A7e37da;
	address public constant VEBPT = 0x19886A88047350482990D4EDd0C1b863646aB921;
	address public feeDistributor = 0xFf23e40ac05D30Df46c250Dd4d784f6496A79CE9;

	/* ========== EVENTS ========== */
	event LockCreated(address indexed user, uint256 value, uint256 duration);
	event TokenClaimed(address indexed user, uint256 value);
	event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
	event Released(address indexed user, uint256 value);
	event GovernanceChanged(address indexed newGovernance);
	event BPTDepositorChanged(address indexed newApwDepositor);
	event AccumulatorChanged(address indexed newAccumulator);
	event FeeDistributorChanged(address indexed newFeeDistributor);

	/* ========== CONSTRUCTOR ========== */
	constructor(address _accumulator) {
		governance = msg.sender;
		accumulator = _accumulator;
		IERC20(BPT).approve(VEBPT, type(uint256).max);
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
		require(msg.sender == governance || msg.sender == bptDepositor, "!(gov||BlackpoolDepositor)");
		_;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Creates a lock by locking BPT token in the VEBPT contract for the specified time
	/// @dev Can only be called by governance or proxy
	/// @param _value The amount of token to be locked
	/// @param _unlockTime The duration for which the token is to be locked
	function createLock(uint256 _value, uint256 _unlockTime) external onlyGovernance {
		VeToken(VEBPT).create_lock(_value, _unlockTime);
		emit LockCreated(msg.sender, _value, _unlockTime);
	}

	/// @notice Increases the amount of BPT locked in VEBPT
	/// @dev The BPT needs to be transferred to this contract before calling
	/// @param _value The amount by which the lock amount is to be increased
	function increaseAmount(uint256 _value) external onlyGovernanceOrDepositor {
		VeToken(VEBPT).increase_amount(_value);
	}

	/// @notice Increases the duration for which BPT is locked in VEBPT for the user calling the function
	/// @param _unlockTime The duration in seconds for which the token is to be locked
	function increaseUnlockTime(uint256 _unlockTime) external onlyGovernanceOrDepositor {
		VeToken(VEBPT).increase_unlock_time(_unlockTime);
	}

	/// @notice Claim the token reward from the BPT fee Distributor passing the token as input parameter
	/// @param _recipient The address which will receive the claimed token reward
	function claimRewards(address _token, address _recipient) external onlyGovernanceOrAcc {
		uint256 claimed = IFeeDistributor(feeDistributor).claim();
		emit TokenClaimed(_recipient, claimed);
		IERC20(_token).safeTransfer(_recipient, claimed);
	}

	/// @notice Withdraw the BPT from VEBPT
	/// @dev call only after lock time expires
	/// @param _recipient The address which will receive the released BPT
	function release(address _recipient) external onlyGovernance {
		VeToken(VEBPT).withdraw();
		uint256 balance = IERC20(BPT).balanceOf(address(this));

		IERC20(BPT).safeTransfer(_recipient, balance);
		emit Released(_recipient, balance);
	}

	/// @notice Set new governance address
	/// @param _governance governance address
	function setGovernance(address _governance) external onlyGovernance {
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	/// @notice Set the BPT Depositor
	/// @param _bptDepositor BPT deppositor address
	function setBptDepositor(address _bptDepositor) external onlyGovernance {
		bptDepositor = _bptDepositor;
		emit BPTDepositorChanged(_bptDepositor);
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