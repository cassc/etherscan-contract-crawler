// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IVeLFT.sol";

interface ILFProxy {
	function getVeLFTUserRewards(uint256[] calldata _pids) external; 
}

interface IRewardPool {
	function rewardToken() external returns(address);
}

interface IWETH {
	function deposit() external payable;
}

/// @title LftLocker
/// @author StakeDAO
/// @notice Locks the LFT token into the LendFlare voting escrow
contract LftLocker {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */
	address public governance;
	address public depositor;
	address public accumulator;

	address public constant LEND_FLARE_PROXY = address(0x77Be80a3c5706973a925C468Bdc8eAcCD187D1Ba);
	address public constant VE_LFT = address(0x19ac8E582A9E6F059E56Ce77015C46e250c711D2);
	address public constant LFT = address(0xB620Be8a1949AA9532e6a3510132864EF9Bc3F82);
	address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

	/* ========== EVENTS ========== */
	event LockCreated(address indexed user, uint256 value, uint256 duration);
	event TokenClaimed(address indexed user, address token, uint256 value);
	event Released(address indexed user, uint256 value);
	event GovernanceChanged(address indexed newGovernance);
	event LftDepositorChanged(address indexed newDepositor);
	event AccumulatorChanged(address indexed newAccumulator);

	/* ========== CONSTRUCTOR ========== */
	constructor(address _accumulator) {
		governance = msg.sender;
		accumulator = _accumulator;
		IERC20(LFT).approve(VE_LFT, type(uint256).max);
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
	/// @notice Creates a lock by locking LFT token in the veLFT contract for the specified time
	/// @dev Can only be called by governance or proxy
	/// @param _value The amount of token to be locked
	/// @param _unlockTime The duration for which the token is to be locked
	function createLock(uint256 _value, uint256 _unlockTime) external onlyGovernance {
		IVeLFT(VE_LFT).createLock(_value, _unlockTime);
		emit LockCreated(msg.sender, _value, _unlockTime);
	}

	/// @notice Increases the amount of LFT locked in veLFT
	/// @dev The LFT needs to be transferred to this contract before calling
	/// @param _value The amount by which the lock amount is to be increased
	function increaseAmount(uint256 _value) external onlyGovernanceOrDepositor {
		IVeLFT(VE_LFT).increaseAmount(_value);
	}

	/// @notice Increases the duration for which LFT is locked in veLFT for the user calling the function
	/// @param _unlockTime The duration in seconds for which the token is to be locked
	function increaseUnlockTime(uint256 _unlockTime) external onlyGovernanceOrDepositor {
		IVeLFT(VE_LFT).increaseUnlockTime(_unlockTime);
	}

	/// @notice Claim the tokens reward from the LendFlare proxy passing a list of pids as input parameter
	/// @param _pids list of base reward pool ids
	/// @param _recipient The address which will receive the claimed tokens rewarded
	function claimRewards(uint256[] calldata _pids, address _recipient) external onlyGovernanceOrAcc {
		ILFProxy(LEND_FLARE_PROXY).getVeLFTUserRewards(_pids);
		for (uint256 i; i < _pids.length;) {
			address rewardPool = IVeLFT(VE_LFT).rewardPools(_pids[i]);
			address token = IRewardPool(rewardPool).rewardToken();
			if (token == address(0)) { // wrap ETH <-> WETH
				IWETH(WETH).deposit{value: address(this).balance}();
				token = WETH;
			}
			uint256 balance = IERC20(token).balanceOf(address(this));
			if (balance > 0) {
				IERC20(token).safeTransfer(_recipient, balance);
				emit TokenClaimed(_recipient, token, balance);
			}
			unchecked{++i;}
		}		
	}

	/// @notice Withdraw the LFT from veLFT
	/// @dev call only after lock time expires
	/// @param _recipient The address which will receive the released LFT
	function release(address _recipient) external onlyGovernance {
		IVeLFT(VE_LFT).withdraw();
		uint256 balance = IERC20(LFT).balanceOf(address(this));

		IERC20(LFT).safeTransfer(_recipient, balance);
		emit Released(_recipient, balance);
	}

	/// @notice Set new governance address
	/// @param _governance governance address
	function setGovernance(address _governance) external onlyGovernance {
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	/// @notice Set the LendFlare Depositor
	/// @param _depositor LFT depositor address
	function setDepositor(address _depositor) external onlyGovernance {
		depositor = _depositor;
		emit LftDepositorChanged(_depositor);
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
	
	// solhint-disable no-empty-blocks
	receive() external payable {
	}
}