// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "contracts/strategy/BaseStrategyV2.sol";
import "contracts/interfaces/FeeDistro.sol";
import "contracts/interfaces/FraxStaking.sol";
import "contracts/interfaces/LiquidityGauge.sol";
import "contracts/interfaces/SdtDistributorV2.sol";

/// @notice Frax Staking Handler.
///         Handle Staking and Withdraw to Frax Gauges through the Locker.
/// @author Stake Dao
contract FraxStrategy is BaseStrategyV2 {
	using SafeERC20 for IERC20;

	constructor(
		ILocker locker,
		address governance,
		address accumulator,
		address veSDTFeeProxy,
		address sdtDistributor,
		address receiver
	) BaseStrategyV2(locker, governance, accumulator, veSDTFeeProxy, sdtDistributor, receiver) {}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice function to deposit into a gauge
	/// @param _token token address
	/// @param _amount amount to deposit
	/// @param _secs locking time in seconds
	function deposit(
		address _token,
		uint256 _amount,
		uint256 _secs
	) external override onlyApprovedVault {
		require(gauges[_token] != address(0), "!gauge");
		address gauge = gauges[_token];

		IERC20(_token).transferFrom(msg.sender, address(LOCKER), _amount);

		// Approve gauge through Locker.
		LOCKER.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", gauge, 0));
		LOCKER.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", gauge, _amount));

		// Deposit through Locker.
		(bool success, ) = LOCKER.execute(
			gauge, // to
			0, // value
			abi.encodePacked(FraxStakingRewardsMultiGauge.stakeLocked.selector, _amount, _secs) // data
		);

		if (!success) {
			revert DepositFailed();
		}

		emit Deposited(gauge, _token, _amount);
	}

	// Withdrawing implies to get claim rewards also.
	/// @notice function to withdraw from a gauge
	/// @param _token token address
	/// @param _kek_id deposit id to withdraw
	function withdraw(address _token, bytes32 _kek_id) external override onlyApprovedVault {
		require(gauges[_token] != address(0), "!gauge");
		address gauge = gauges[_token];

		uint256 before = IERC20(_token).balanceOf(address(LOCKER));

		(bool success, ) = LOCKER.execute(
			gauge,
			0,
			abi.encodePacked(FraxStakingRewardsMultiGauge.withdrawLocked.selector, _kek_id)
		);

		if (!success) {
			revert WithdrawalFailed();
		}

		uint256 _after = IERC20(_token).balanceOf(address(LOCKER));
		uint256 net = _after - before;

		_transferFromLocker(_token, msg.sender, net);
		_distributeRewards(gauge);

		emit Withdrawn(gauge, _token, net);
	}

	/// @notice function to claim the reward and distribute it
	/// @param _token token address
	function claim(address _token) external override {
		address gauge = gauges[_token];
		require(gauge != address(0), "!gauge");

		(bool success, ) = LOCKER.execute(gauge, 0, abi.encode(FraxStakingRewardsMultiGauge.getReward.selector));
		require(success, "Claim failed!");

		_distributeRewards(gauge);
	}

	/// @notice internal function used for distributing rewards
	/// @param _gauge gauge address
	function _distributeRewards(address _gauge) internal {
		address[] memory rewardsToken = FraxStakingRewardsMultiGauge(_gauge).getAllRewardTokens();
		uint256 lenght = rewardsToken.length;

		SdtDistributorV2(sdtDistributor).distribute(multiGauges[_gauge]);

		for (uint256 i; i < lenght; ) {
			address rewardToken = rewardsToken[i];
			if (rewardToken == address(0)) {
				continue;
			}

			uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(LOCKER));
			uint256 netBalance = _distributeFees(_gauge, rewardToken, rewardBalance);

			// Distribute net rewards to gauge.
			IERC20(rewardToken).approve(multiGauges[_gauge], netBalance);
			LiquidityGauge(multiGauges[_gauge]).deposit_reward_token(rewardToken, netBalance);

			emit Claimed(_gauge, rewardToken, rewardBalance);

			unchecked {
				++i;
			}
		}
	}

	/// @notice internal function used for distributing fees
	/// @param _gauge gauge address
	/// @param _rewardToken reward token address
	/// @param _rewardBalance amount of reward
	function _distributeFees(
		address _gauge,
		address _rewardToken,
		uint256 _rewardBalance
	) internal returns (uint256 netRewards) {
		uint256 multisigFee = (_rewardBalance * perfFee[_gauge]) / BASE_FEE;
		uint256 accumulatorPart = (_rewardBalance * accumulatorFee[_gauge]) / BASE_FEE;
		uint256 veSDTPart = (_rewardBalance * veSDTFee[_gauge]) / BASE_FEE;
		uint256 claimerPart = (_rewardBalance * claimerRewardFee[_gauge]) / BASE_FEE;

		// Distribute fees.
		_transferFromLocker(_rewardToken, msg.sender, claimerPart);
		_transferFromLocker(_rewardToken, veSDTFeeProxy, veSDTPart);
		_transferFromLocker(_rewardToken, accumulator, accumulatorPart);
		_transferFromLocker(_rewardToken, rewardsReceiver, multisigFee);

		// Update rewardAmount.
		netRewards = IERC20(_rewardToken).balanceOf(address(LOCKER));
		_transferFromLocker(_rewardToken, address(this), netRewards);
	}

	/// @notice internal function used for transfering token from locker
	/// @param _token token address
	/// @param _recipient receipient address
	/// @param _amount amount to transfert
	function _transferFromLocker(
		address _token,
		address _recipient,
		uint256 _amount
	) internal {
		(bool success, ) = LOCKER.execute(
			_token,
			0,
			abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount)
		);
		if (!success) {
			revert TransferFromLockerFailed();
		}
	}

	/// @notice only callable by approvedVault, used for allow delegating veFXS boost to a vault
	/// @param _to Address to sent the value to
	/// @param _data Call function data
	function proxyCall(address _to, bytes memory _data) external onlyApprovedVault {
		(bool success, ) = LOCKER.execute(_to, uint256(0), _data);
		require(success, "Proxy Call Fail");
	}

	// BaseStrategy Function
	/// @notice not implemented
	function deposit(address, uint256) external view override onlyApprovedVault {
		revert NotImplemented();
	}

	// BaseStrategy Function
	/// @notice not implemented
	function withdraw(address, uint256) external view override onlyApprovedVault {
		revert NotImplemented();
	}

	/// @notice function to toggle a vault
	/// @param _vault vault address
	function toggleVault(address _vault) external override onlyGovernanceOrFactory {
		require(_vault != address(0), "zero address");
		vaults[_vault] = !vaults[_vault];
		emit VaultToggled(_vault, vaults[_vault]);
	}

	/// @notice function to set a new gauge
	/// It permits to set it as  address(0), for disabling it
	/// in case of migration
	/// @param _token token address
	/// @param _gauge gauge address
	function setGauge(address _token, address _gauge) external override onlyGovernanceOrFactory {
		require(_token != address(0), "zero address");
		// Set new gauge
		gauges[_token] = _gauge;
		emit GaugeSet(_gauge, _token);
	}

	/// @notice function to set a multi gauge
	/// @param _gauge gauge address
	/// @param _multiGauge multi gauge address
	function setMultiGauge(address _gauge, address _multiGauge) external override onlyGovernanceOrFactory {
		multiGauges[_gauge] = _multiGauge;
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