// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseStrategy.sol";
import "../accumulator/CurveAccumulator.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/IMultiRewards.sol";
import "../staking/SdtDistributorV2.sol";

contract CurveStrategy is BaseStrategy {
	using SafeERC20 for IERC20;

	CurveAccumulator public accumulator;
	address public sdtDistributor;
	address public constant CRV_FEE_D = 0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc;
	address public constant CRV3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
	address public constant CRV_MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
	address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
	mapping(address => uint256) public lGaugeType;

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

	event Crv3Claimed(uint256 amount, bool notified);

	/* ========== CONSTRUCTOR ========== */
	constructor(
		ILocker _locker,
		address _governance,
		address _receiver,
		CurveAccumulator _accumulator,
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

	/// @notice function to claim the reward
	/// @param _token token address
	function claim(address _token) external override {
		address gauge = gauges[_token];
		require(gauge != address(0), "!gauge");

		uint256 crvBeforeClaim = IERC20(CRV).balanceOf(address(locker));

		// Claim CRV
		// within the mint() it calls the user checkpoint
		(bool success, ) = locker.execute(CRV_MINTER, 0, abi.encodeWithSignature("mint(address)", gauge));
		require(success, "CRV mint failed!");

		uint256 crvMinted = IERC20(CRV).balanceOf(address(locker)) - crvBeforeClaim;

		// Send CRV here
		(success, ) = locker.execute(
			CRV,
			0,
			abi.encodeWithSignature("transfer(address,uint256)", address(this), crvMinted)
		);
		require(success, "CRV transfer failed!");

		// Distribute CRV
		uint256 crvNetRewards = sendFee(gauge, CRV, crvMinted);
		IERC20(CRV).approve(multiGauges[gauge], crvNetRewards);
		ILiquidityGauge(multiGauges[gauge]).deposit_reward_token(CRV, crvNetRewards);
		emit Claimed(gauge, CRV, crvMinted);

		// Distribute SDT to the related gauge
		SdtDistributorV2(sdtDistributor).distribute(multiGauges[gauge]);

		// Claim rewards only for lg type 0 and if there is at least one reward token added
		if (lGaugeType[gauge] == 0 && ILiquidityGauge(gauge).reward_tokens(0) != address(0)) {
			(success, ) = locker.execute(
				gauge,
				0,
				abi.encodeWithSignature("claim_rewards(address,address)", address(locker), address(this))
			);
			if (!success) {
				// Claim on behalf of locker
				ILiquidityGauge(gauge).claim_rewards(address(locker));
			}
			address rewardToken;
			uint256 rewardsBalance;
			for (uint8 i = 0; i < 8; i++) {
				rewardToken = ILiquidityGauge(gauge).reward_tokens(i);
				if (rewardToken == address(0)) {
					break;
				}
				if (success) {
					rewardsBalance = IERC20(rewardToken).balanceOf(address(this));
				} else {
					rewardsBalance = IERC20(rewardToken).balanceOf(address(locker));
					(success, ) = locker.execute(
						rewardToken,
						0,
						abi.encodeWithSignature("transfer(address,uint256)", address(this), rewardsBalance)
					);
					require(success, "Transfer failed");
				}
				IERC20(rewardToken).approve(multiGauges[gauge], rewardsBalance);
				ILiquidityGauge(multiGauges[gauge]).deposit_reward_token(rewardToken, rewardsBalance);
				emit Claimed(gauge, rewardToken, rewardsBalance);
			}
		}
	}

	function sendFee(
		address _gauge,
		address _rewardToken,
		uint256 _rewardsBalance
	) internal returns (uint256) {
		// calculate the amount for each fee recipient
		uint256 multisigFee = (_rewardsBalance * perfFee[_gauge]) / BASE_FEE;
		uint256 accumulatorPart = (_rewardsBalance * accumulatorFee[_gauge]) / BASE_FEE;
		uint256 veSDTPart = (_rewardsBalance * veSDTFee[_gauge]) / BASE_FEE;
		uint256 claimerPart = (_rewardsBalance * claimerRewardFee[_gauge]) / BASE_FEE;
		// send
		IERC20(_rewardToken).approve(address(accumulator), accumulatorPart);
		accumulator.depositToken(_rewardToken, accumulatorPart);
		IERC20(_rewardToken).transfer(rewardsReceiver, multisigFee);
		IERC20(_rewardToken).transfer(veSDTFeeProxy, veSDTPart);
		IERC20(_rewardToken).transfer(msg.sender, claimerPart);
		return _rewardsBalance - multisigFee - accumulatorPart - veSDTPart - claimerPart;
	}

	/// @notice function to claim 3crv every week from the curve Fee Distributor
	/// @param _notify choose if claim or claim and notify the amount to the related gauge
	function claim3Crv(bool _notify) external {
		// Claim 3crv from the curve fee Distributor
		// It will send 3crv to the crv locker
		bool success;
		(success, ) = locker.execute(CRV_FEE_D, 0, abi.encodeWithSignature("claim()"));
		require(success, "3crv claim failed");
		// Send 3crv from the locker to the accumulator
		uint256 amountToSend = IERC20(CRV3).balanceOf(address(locker));
		require(amountToSend > 0, "nothing claimed");
		(success, ) = locker.execute(
			CRV3,
			0,
			abi.encodeWithSignature("transfer(address,uint256)", address(accumulator), amountToSend)
		);
		require(success, "3crv transfer failed");
		if (_notify) {
			accumulator.notifyAll();
		}
		emit Crv3Claimed(amountToSend, _notify);
	}

	/// @notice function to toggle a vault
	/// @param _vault vault address
	function toggleVault(address _vault) external override onlyGovernanceOrFactory {
		require(_vault != address(0), "zero address");
		vaults[_vault] = !vaults[_vault];
		emit VaultToggled(_vault, vaults[_vault]);
	}

	/// @notice function to set a gauge type
	/// @param _gauge gauge address
	/// @param _gaugeType type of gauge
	function setLGtype(address _gauge, uint256 _gaugeType) external onlyGovernanceOrFactory {
		lGaugeType[_gauge] = _gaugeType;
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

	/// @notice function to migrate any LP to another strategy contract (hard migration)
	/// @param _token token address
	function migrateLP(address _token) external onlyApprovedVault {
		require(gauges[_token] != address(0), "not existent gauge");
		migrate(_token);
	}

	/// @notice function to migrate any LP, it sends them to the vault
	/// @param _token token address
	function migrate(address _token) internal {
		address gauge = gauges[_token];
		uint256 amount = IERC20(gauge).balanceOf(address(locker));
		// Withdraw LPs from the old gauge
		(bool success, ) = locker.execute(gauge, 0, abi.encodeWithSignature("withdraw(uint256)", amount));
		require(success, "Withdraw failed!");

		// Transfer LPs to the approved vault
		(success, ) = locker.execute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
		require(success, "Transfer failed!");
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
		accumulator = CurveAccumulator(_newAccumulator);
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