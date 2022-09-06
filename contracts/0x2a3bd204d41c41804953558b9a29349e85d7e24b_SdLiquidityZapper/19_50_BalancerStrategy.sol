// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseStrategy.sol";
import "../accumulator/BalancerAccumulator.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/IMultiRewards.sol";
import "../staking/SdtDistributorV2.sol";

contract BalancerStrategy is BaseStrategy {
	using SafeERC20 for IERC20;

	BalancerAccumulator public accumulator;
	address public sdtDistributor;
	address public constant BAL_MINTER = 0x239e55F427D44C3cc793f49bFB507ebe76638a2b;
	address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;

	struct ClaimerReward {
		address rewardToken;
		uint256 amount;
	}

	enum MANAGEFEE {
		PERFFEE,
		VESDTFEE,
		ACCUMULATORFEE,
		CLAIMERREWARD
	}

	/* ========== CONSTRUCTOR ========== */
	constructor(
		ILocker _locker,
		address _governance,
		address _receiver,
		BalancerAccumulator _accumulator,
		address _veSDTFeeProxy,
		address _sdtDistributor
	) BaseStrategy(_locker, _governance, _receiver) {
		accumulator = _accumulator;
		veSDTFeeProxy = _veSDTFeeProxy;
		sdtDistributor = _sdtDistributor;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice function to deposit into a gauge
	/// @param _token token address
	/// @param _amount amount to deposit
	function deposit(address _token, uint256 _amount) external override onlyApprovedVault {
		IERC20(_token).transferFrom(msg.sender, address(locker), _amount);
		address gauge = gauges[_token];
		require(gauge != address(0), "!gauge");
		locker.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", gauge, 0));
		locker.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", gauge, _amount));

		(bool success, ) = locker.execute(gauge, 0, abi.encodeWithSignature("deposit(uint256)", _amount));
		require(success, "Deposit failed!");
		emit Deposited(gauge, _token, _amount);
	}

	/// @notice function to withdraw from a gauge
	/// @param _token token address
	/// @param _amount amount to withdraw
	function withdraw(address _token, uint256 _amount) external override onlyApprovedVault {
		uint256 _before = IERC20(_token).balanceOf(address(locker));
		address gauge = gauges[_token];
		require(gauge != address(0), "!gauge");
		(bool success, ) = locker.execute(gauge, 0, abi.encodeWithSignature("withdraw(uint256)", _amount));
		require(success, "Transfer failed!");
		uint256 _after = IERC20(_token).balanceOf(address(locker));

		uint256 _net = _after - _before;
		(success, ) = locker.execute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _net));
		require(success, "Transfer failed!");
		emit Withdrawn(gauge, _token, _amount);
	}

	/// @notice function to send funds into the related accumulator
	/// @param _token token address
	/// @param _amount amount to send
	function sendToAccumulator(address _token, uint256 _amount) external onlyGovernance {
		IERC20(_token).approve(address(accumulator), _amount);
		accumulator.depositToken(_token, _amount);
	}

	/// @notice function to claim the reward and distribute it
	/// @param _token BPT token address
	function claim(address _token) external override {
		address gauge = gauges[_token];
		require(gauge != address(0), "!gauge");

		uint256 balBeforeClaim = IERC20(BAL).balanceOf(address(locker));

		// Claim BAL
		// within the mint() it calls the user checkpoint
		(bool success, ) = locker.execute(BAL_MINTER, 0, abi.encodeWithSignature("mint(address)", gauge));
		require(success, "BAL mint failed!");

		uint256 balMinted = IERC20(BAL).balanceOf(address(locker)) - balBeforeClaim;

		// Send BAL here
		(success, ) = locker.execute(
			BAL,
			0,
			abi.encodeWithSignature("transfer(address,uint256)", address(this), balMinted)
		);
		require(success, "BAL transfer failed!");

		// Distribute BAL
		uint256 balNetRewards = sendFee(gauge, balMinted);
		IERC20(BAL).approve(multiGauges[gauge], balNetRewards);
		ILiquidityGauge(multiGauges[gauge]).deposit_reward_token(BAL, balNetRewards);
		emit Claimed(gauge, BAL, balMinted);

		// Distribute SDT to the related gauge
		SdtDistributorV2(sdtDistributor).distribute(multiGauges[gauge]);

		// Claim rewards only if there is at least one extra reward
		if (ILiquidityGauge(gauge).reward_tokens(0) != address(0)) {
			(success, ) = locker.execute(
				gauge,
				0,
				abi.encodeWithSignature("claim_rewards(address,address)", address(locker), address(this))
			);
			address rewardToken;
			uint256 rewardsBalance;
			for (uint8 i = 0; i < 8; i++) {
				rewardToken = ILiquidityGauge(gauge).reward_tokens(i);
				if (rewardToken == address(0)) {
					break;
				}
				rewardsBalance = IERC20(rewardToken).balanceOf(address(this));
				IERC20(rewardToken).approve(multiGauges[gauge], rewardsBalance);
				ILiquidityGauge(multiGauges[gauge]).deposit_reward_token(rewardToken, rewardsBalance);
				emit Claimed(gauge, rewardToken, rewardsBalance);
			}
		}
	}

	/// @notice internal function for distributing fees to recipients
	/// @param _gauge gauge address
	/// @param _rewardsBalance total balance to distribute
	function sendFee(address _gauge, uint256 _rewardsBalance) internal returns (uint256) {
		// calculate the amount for each fee recipient
		uint256 multisigFee = (_rewardsBalance * perfFee[_gauge]) / BASE_FEE;
		uint256 accumulatorPart = (_rewardsBalance * accumulatorFee[_gauge]) / BASE_FEE;
		uint256 veSDTPart = (_rewardsBalance * veSDTFee[_gauge]) / BASE_FEE;
		uint256 claimerPart = (_rewardsBalance * claimerRewardFee[_gauge]) / BASE_FEE;
		// send
		IERC20(BAL).approve(address(accumulator), accumulatorPart);
		accumulator.depositToken(BAL, accumulatorPart);
		IERC20(BAL).transfer(rewardsReceiver, multisigFee);
		IERC20(BAL).transfer(veSDTFeeProxy, veSDTPart);
		IERC20(BAL).transfer(msg.sender, claimerPart);
		return _rewardsBalance - multisigFee - accumulatorPart - veSDTPart - claimerPart;
	}

	/// @notice function to toggle a vault
	/// @param _vault vault address
	function toggleVault(address _vault) external override onlyGovernanceOrFactory {
		require(_vault != address(0), "zero address");
		vaults[_vault] = !vaults[_vault];
		emit VaultToggled(_vault, vaults[_vault]);
	}

	/// @notice function to set a new gauge
	/// It permits to set it as address(0), for disabling it
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
		require(_gauge != address(0), "zero address");
		require(_multiGauge != address(0), "zero address");
		multiGauges[_gauge] = _multiGauge;
	}

	/// @notice function to set a new veSDTProxy
	/// @param _newVeSDTProxy veSdtProxy address
	function setVeSDTProxy(address _newVeSDTProxy) external onlyGovernance {
		require(_newVeSDTProxy != address(0), "zero address");
		veSDTFeeProxy = _newVeSDTProxy;
	}

	/// @notice function to set a new accumulator
	/// @param _newAccumulator accumulator address
	function setAccumulator(address _newAccumulator) external onlyGovernance {
		require(_newAccumulator != address(0), "zero address");
		accumulator = BalancerAccumulator(_newAccumulator);
	}

	/// @notice function to set a new reward receiver
	/// @param _newRewardsReceiver reward receiver address
	function setRewardsReceiver(address _newRewardsReceiver) external onlyGovernance {
		require(_newRewardsReceiver != address(0), "zero address");
		rewardsReceiver = _newRewardsReceiver;
	}

	/// @notice function to set a new governance address
	/// @param _newGovernance governance address
	function setGovernance(address _newGovernance) external onlyGovernance {
		require(_newGovernance != address(0), "zero address");
		governance = _newGovernance;
	}

	/// @notice function to set the vault/gauge factory
	/// @param _newVaultGaugeFactory factory address
	function setVaultGaugeFactory(address _newVaultGaugeFactory) external onlyGovernance {
		require(_newVaultGaugeFactory != address(0), "zero address");
		vaultGaugeFactory = _newVaultGaugeFactory;
	}

	/// @notice function to set new fees
	/// @param _manageFee manageFee
	/// @param _gauge gauge address
	/// @param _newFee new fee to set
	function manageFee(
		MANAGEFEE _manageFee,
		address _gauge,
		uint256 _newFee
	) external onlyGovernanceOrFactory {
		require(_gauge != address(0), "zero address");
		if (_manageFee == MANAGEFEE.PERFFEE) {
			// 0
			perfFee[_gauge] = _newFee;
		} else if (_manageFee == MANAGEFEE.VESDTFEE) {
			// 1
			veSDTFee[_gauge] = _newFee;
		} else if (_manageFee == MANAGEFEE.ACCUMULATORFEE) {
			//2
			accumulatorFee[_gauge] = _newFee;
		} else if (_manageFee == MANAGEFEE.CLAIMERREWARD) {
			// 3
			claimerRewardFee[_gauge] = _newFee;
		}
		require(
			perfFee[_gauge] + veSDTFee[_gauge] + accumulatorFee[_gauge] + claimerRewardFee[_gauge] <= BASE_FEE,
			"fee to high"
		);
	}

	/// @notice execute a function
	/// @param _to Address to sent the value to
	/// @param _value Value to be sent
	/// @param _data Call function data
	function execute(
		address _to,
		uint256 _value,
		bytes calldata _data
	) external onlyGovernance returns (bool, bytes memory) {
		(bool success, bytes memory result) = _to.call{ value: _value }(_data);
		return (success, result);
	}
}