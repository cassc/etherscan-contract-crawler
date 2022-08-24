// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/VeToken.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/BalancerFeeDistributor.sol";

/// @title BalancerLocker
/// @author StakeDAO
/// @notice Locks the B-80BAL-20WETH tokens to veBAL contract
contract BalancerLocker {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public depositor;
	address public accumulator;

	address public constant BALANCER_POOL_TOKEN = address(0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56);
	address public constant veBAL = address(0xC128a9954e6c874eA3d62ce62B468bA073093F25);

	address public feeDistributor = address(0x26743984e3357eFC59f2fd6C1aFDC310335a61c9);
	address public gaugeController = address(0xC128468b7Ce63eA702C1f104D55A2566b13D3ABD);

	/* ========== EVENTS ========== */
	event LockCreated(address indexed user, uint256 value, uint256 duration);
	event TokenClaimed(address indexed user, address token, uint256 value);
	event TokensClaimed(address indexed user, address[] tokens, uint256[] value);
	event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
	event Released(address indexed user, uint256 value);
	event GovernanceChanged(address indexed newGovernance);
	event BalancerDepositorChanged(address indexed newDepositor);
	event AccumulatorChanged(address indexed newAccumulator);
	event FeeDistributorChanged(address indexed newFeeDistributor);
	event GaugeControllerChanged(address indexed newGaugeController);

	/* ========== CONSTRUCTOR ========== */
	constructor(address _accumulator) {
		governance = msg.sender;
		accumulator = _accumulator;
		IERC20(BALANCER_POOL_TOKEN).approve(veBAL, type(uint256).max);
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
		require(msg.sender == governance || msg.sender == depositor, "!(gov||Depositor)");
		_;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Creates a lock by locking BALANCER_POOL_TOKEN token in the veBAL contract for the specified time
	/// @dev Can only be called by governance or proxy
	/// @param _value The amount of token to be locked
	/// @param _unlockTime The duration for which the token is to be locked
	function createLock(uint256 _value, uint256 _unlockTime) external onlyGovernance {
		VeToken(veBAL).create_lock(_value, _unlockTime);
		emit LockCreated(msg.sender, _value, _unlockTime);
	}

	/// @notice Increases the amount of BALANCER_POOL_TOKEN locked in veBAL
	/// @dev The BALANCER_POOL_TOKEN needs to be transferred to this contract before calling
	/// @param _value The amount by which the lock amount is to be increased
	function increaseAmount(uint256 _value) external onlyGovernanceOrDepositor {
		VeToken(veBAL).increase_amount(_value);
	}

	/// @notice Increases the duration for which BALANCER_POOL_TOKEN is locked in veBAL for the user calling the function
	/// @param _unlockTime The duration in seconds for which the token is to be locked
	function increaseUnlockTime(uint256 _unlockTime) external onlyGovernanceOrDepositor {
		VeToken(veBAL).increase_unlock_time(_unlockTime);
	}

	/// @notice Claim the token reward from the BALANCER_POOL_TOKEN fee Distributor passing the token as input parameter
	/// @param _recipient The address which will receive the claimed token reward
	function claimRewards(address _token, address _recipient) external onlyGovernanceOrAcc {
		uint256 claimed = BalancerFeeDistributor(feeDistributor).claimToken(address(this), _token);
		emit TokenClaimed(_recipient, _token, claimed);
		IERC20(_token).safeTransfer(_recipient, claimed);
	}

	function claimAllRewards(address[] calldata _tokens, address _recipient) external onlyGovernanceOrAcc {
		uint256[] memory claimed = BalancerFeeDistributor(feeDistributor).claimTokens(address(this), _tokens);
		uint256 length = _tokens.length;
		for (uint256 i; i < length; ++i) {
			IERC20(_tokens[i]).safeTransfer(_recipient, claimed[i]);
		}
		emit TokensClaimed(_recipient, _tokens, claimed);
	}

	/// @notice Withdraw the BALANCER_POOL_TOKEN from veBAL
	/// @dev call only after lock time expires
	/// @param _recipient The address which will receive the released BALANCER_POOL_TOKEN
	function release(address _recipient) external onlyGovernance {
		VeToken(veBAL).withdraw();
		uint256 balance = IERC20(BALANCER_POOL_TOKEN).balanceOf(address(this));

		IERC20(BALANCER_POOL_TOKEN).safeTransfer(_recipient, balance);
		emit Released(_recipient, balance);
	}

	/// @notice Vote on Balancer Gauge Controller for a gauge with a given weight
	/// @param _gauge The gauge address to vote for
	/// @param _weight The weight with which to vote
	function voteGaugeWeight(address _gauge, uint256 _weight) external onlyGovernance {
		IGaugeController(gaugeController).vote_for_gauge_weights(_gauge, _weight);
		emit VotedOnGaugeWeight(_gauge, _weight);
	}

	/// @notice Set new governance address
	/// @param _governance governance address
	function setGovernance(address _governance) external onlyGovernance {
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	/// @notice Set the Balancer Depositor
	/// @param _depositor BALANCER_POOL_TOKEN deppositor address
	function setDepositor(address _depositor) external onlyGovernance {
		depositor = _depositor;
		emit BalancerDepositorChanged(_depositor);
	}

	/// @notice Set the fee distributor
	/// @param _newFD fee distributor address
	function setFeeDistributor(address _newFD) external onlyGovernance {
		feeDistributor = _newFD;
		emit FeeDistributorChanged(_newFD);
	}

	/// @notice Set the gauge controller
	/// @param _gaugeController gauge controller address
	function setGaugeController(address _gaugeController) external onlyGovernance {
		gaugeController = _gaugeController;
		emit GaugeControllerChanged(_gaugeController);
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