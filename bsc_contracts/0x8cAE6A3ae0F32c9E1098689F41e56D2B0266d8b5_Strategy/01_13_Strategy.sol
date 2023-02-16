// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { BaseStrategy, StrategyParams } from "./BaseStrategy.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { SafeERC20 } from "./library/SafeERC20.sol";
import { SafeMath } from "./library/SafeMath.sol";
import { Address } from "./library/Address.sol";
import { ERC20 } from "./library/ERC20.sol";
import { Math } from "./library/Math.sol";

import { IStargateRouter } from "../interfaces/IStargateRouter.sol";
import { IMasterChef } from "../interfaces/IMasterChef.sol";
import { IUni } from "../interfaces/IUniswapV2Router02.sol";
import { ILpPool } from "../interfaces/IPool.sol";

contract Strategy is BaseStrategy {
	using Address for address;
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	IERC20 public constant rewardToken = IERC20(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b); // Stargate Token
	ILpPool public constant lpToken = ILpPool(0x98a5737749490856b401DB5Dc27F522fC314A4e1); // USDT LP (S*USDT)

	IStargateRouter public stargateRouter;
	uint16 internal liquidityPoolId;

	bool internal abandonRewards;
	uint256 public wantDust;
	uint256 public rewardsDust;

	IMasterChef public masterChef;
	uint256 internal masterChefPoolId;

	uint256 internal constant MAX = type(uint256).max;

	IUni internal constant router = IUni(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeSwap

	bool public collectFeesEnabled = false;
	uint256 public maxSlippageIn = 5; // bps
	uint256 public maxSlippageOut = 5; // bps
	uint256 internal constant basisOne = 10000;

	uint256 public minProfit;
	bool internal forceHarvestTriggerOnce;

	constructor(
		address _vault,
		address _masterChef,
		uint256 _masterChefPoolId,
		address _stargateRouter,
		uint16 _liquidityPoolId
	) public BaseStrategy(_vault) {
		maxReportDelay = 30 days;
		minProfit = 1e21; // 1000 BUSD

		wantDust = 1e18; // BUSD in BSC has 18 decimals
		rewardsDust = 1e18;

		stargateRouter = IStargateRouter(_stargateRouter); // 0x4a364f8c717cAAD9A442737Eb7b8A55cc6cf18D8
		liquidityPoolId = _liquidityPoolId; // 5 is BUSD

		masterChef = IMasterChef(_masterChef); // 0x3052A0F6ab15b4AE1df39962d5DdEFacA86DaB47
		masterChefPoolId = _masterChefPoolId; // 1 is BUSD
		require(
			address(masterChef.poolInfo(masterChefPoolId).lpToken) == address(lpToken),
			"Wrong pool"
		);

		assert(lpToken.poolId() == uint256(_liquidityPoolId)); // Sanity check
		assert(lpToken.router() == _stargateRouter); // Sanity check

		_giveAllowances();
	}

	//--------------------------//
	// 	    Public Methods 		//
	//--------------------------//

	function name() external view override returns (string memory) {
		return string(abi.encodePacked("SS USDT Stargate Strategy"));
	}

	function balanceOfWant() public view returns (uint256) {
		return want.balanceOf(address(this));
	}

	function balanceOfLPInMasterChef() public view returns (uint256 _amount) {
		(_amount, ) = masterChef.userInfo(masterChefPoolId, address(this));
	}

	function balanceOfLpTokens() public view returns (uint256) {
		return lpToken.balanceOf(address(this));
	}

	function balanceOfReward() public view returns (uint256) {
		return rewardToken.balanceOf(address(this));
	}

	function estimatedTotalAssets() public view override returns (uint256) {
		return balanceOfPooled().add(balanceOfWant()); // Staked and free Tokens
	}

	function balanceOfPooled() public view returns (uint256) {
		uint256 _lpBalance = balanceOfLpTokens().add(balanceOfLPInMasterChef());
		return lpToken.amountLPtoLD(_lpBalance);
	}

	function wantToLPToken(uint256 _wantAmount) public view returns (uint256) {
		return _wantAmount.mul(lpToken.totalSupply()).div(lpToken.totalLiquidity()).div(1e12); // Need scaling LpToken has 6 decimals
	}

	function pendingRewards() public view returns (uint256 _pendingRewards) {
		_pendingRewards = masterChef.pendingStargate(masterChefPoolId, address(this));
	}

	function estimatedHarvest() public view returns (uint256 _profitInUSDT) {
		uint256 _stargateBalance = pendingRewards().add(balanceOfReward());

		address[] memory rewardToWant = new address[](2);
		rewardToWant[0] = address(rewardToken);
		rewardToWant[1] = address(want); // There is a pool for BUSD-USDT in Pancake

		if (_stargateBalance > 0) {
			uint256 priceInWant = router.getAmountsOut(1e18, rewardToWant)[rewardToWant.length - 1];
			_profitInUSDT = _stargateBalance.mul(priceInWant).div(1e18);
		}
	}

	//-------------------------------//
	//      Internal Core func       //
	//-------------------------------//

	function prepareReturn(uint256 _debtOutstanding)
		internal
		override
		returns (
			uint256 _profit,
			uint256 _loss,
			uint256 _debtPayment
		)
	{
		if (_debtOutstanding > 0) {
			(_debtPayment, _loss) = liquidatePosition(_debtOutstanding);
		}
		if (collectFeesEnabled) {
			_collectTradingFees();
		}
		_claimRewards(); // Claim Stargate rewards
		_sellAllRewards(); // Sell Rewards for want (USDC) token

		uint256 debt = vault.strategies(address(this)).totalDebt;
		uint256 balance = estimatedTotalAssets();
		uint256 wantBalance = balanceOfWant();

		if (balance > debt) {
			_profit = balance.sub(debt);
			_loss = 0;
			if (wantBalance < _profit) {
				// All reserve is profit
				_profit = wantBalance;
				_debtPayment = 0;
			} else if (wantBalance > _profit.add(_debtOutstanding)) {
				_debtPayment = _debtOutstanding;
			} else {
				_debtPayment = wantBalance.sub(_profit);
			}
		} else {
			// This has an unintended side effect of slowly lowering our total debt allowed
			_loss = debt.sub(balance);
			_debtPayment = Math.min(wantBalance, _debtOutstanding);
		}

		// We're done harvesting, so reset our trigger if we used it
		forceHarvestTriggerOnce = false;
	}

	function adjustPosition(uint256 _debtOutstanding) internal override {
		// LP assets before the operation
		uint256 pooledBefore = balanceOfPooled();
		// Claim Stargate rewards
		_claimRewards();
		// If we have rewards to sell we sell them
		_sellAllRewards();
		uint256 amountIn = balanceOfWant();
		if (amountIn > wantDust) {
			_addLiquidity(amountIn);
			_depositLpIntoMasterChef();
			uint256 investedWant = amountIn.sub(balanceOfWant());
			_enforceSlippageIn(investedWant, pooledBefore);
		}
	}

	function liquidatePosition(uint256 _amountNeeded)
		internal
		override
		returns (uint256 _liquidatedAmount, uint256 _loss)
	{
		if (estimatedTotalAssets() < _amountNeeded) {
			_liquidatedAmount = liquidateAllPositions();
			_loss = _amountNeeded < _liquidatedAmount ? 0 : _amountNeeded.sub(_liquidatedAmount);
			return (_liquidatedAmount, _loss);
		}

		uint256 looseAmount = balanceOfWant();
		if (_amountNeeded > looseAmount) {
			uint256 toExitAmount = _amountNeeded.sub(looseAmount);

			_withdrawFromMasterChef(); // Withdraw all LP form masterChef
			_removeLiquidity(wantToLPToken(toExitAmount)); // Remove liquidity to get want tokens
			_depositLpIntoMasterChef(); // Re-Deposit all unused LP tokens to masterChef

			_liquidatedAmount = Math.min(balanceOfWant(), _amountNeeded);
			_loss = _amountNeeded.sub(_liquidatedAmount);
			_enforceSlippageOut(toExitAmount, _liquidatedAmount.sub(looseAmount));
		} else {
			// We have enough balance to cover the liquidation
			return (_amountNeeded, 0);
		}
	}

	function liquidateAllPositions() internal override returns (uint256 _liquidated) {
		uint256 eta = estimatedTotalAssets();
		// Withdraw all Lp out of masterChef
		_withdrawFromMasterChef();
		// Convert to want tokens
		_removeLiquidity(balanceOfLpTokens());
		// Calculate how many want we have liquidated
		_liquidated = balanceOfWant();

		_enforceSlippageOut(eta, _liquidated);
		return _liquidated;
	}

	function prepareMigration(address _newStrategy) internal override {
		_withdrawFromMasterChefAndTransfer(_newStrategy);
	}

	function _collectTradingFees() internal {
		uint256 totalAssets = estimatedTotalAssets();
		uint256 strategyDebt = vault.strategies(address(this)).totalDebt;

		if (totalAssets > strategyDebt) {
			uint256 profit = totalAssets.sub(strategyDebt);
			// Liquidate an exact amount of Lp tokens
			if (profit > wantDust) {
				liquidatePosition(profit);
			}
		}
	}

	// Sell from reward token to want
	function _sellAllRewards() internal {
		uint256 rewardsBalance = balanceOfReward();

		address[] memory path = new address[](2);
		path[0] = address(rewardToken);
		path[1] = address(want);

		if (rewardsBalance > rewardsDust) {
			router.swapExactTokensForTokens(
				rewardsBalance,
				uint256(0),
				path,
				address(this),
				block.timestamp
			);
		}
	}

	function _claimRewards() internal {
		masterChef.deposit(masterChefPoolId, 0); // Note no harvest function available
	}

	function _withdrawFromMasterChef() internal {
		uint256 masterChefBal = balanceOfLPInMasterChef();
		if (masterChefBal > 0) {
			masterChef.withdraw(masterChefPoolId, masterChefBal);
		}
	}

	function _depositLpIntoMasterChef() internal {
		if (balanceOfLpTokens() > 0) {
			masterChef.deposit(masterChefPoolId, balanceOfLpTokens());
		}
	}

	function _addLiquidity(uint256 _amountToInvest) internal {
		stargateRouter.addLiquidity(liquidityPoolId, _amountToInvest, address(this));
	}

	function _removeLiquidity(uint256 _lpToExit) internal {
		uint256 totalLpBalance = balanceOfLpTokens().add(balanceOfLPInMasterChef());
		uint256 lpToExit = Math.min(_lpToExit, totalLpBalance);
		stargateRouter.instantRedeemLocal(liquidityPoolId, lpToExit, address(this));
	}

	// Enforce that amount exchange from want to LP tokens didn't slip beyond our tolerance.
	// Check for positive slippage, just in case.
	function _enforceSlippageIn(uint256 _amountIn, uint256 _pooledBefore) internal view {
		uint256 pooledDelta = balanceOfPooled().sub(_pooledBefore);
		uint256 joinSlipped = _amountIn > pooledDelta ? _amountIn.sub(pooledDelta) : 0;
		uint256 maxLoss = _amountIn.mul(maxSlippageIn).div(basisOne);
		require(joinSlipped <= maxLoss, "Slipped in!");
	}

	// Enforce that amount exited didn't slip beyond our tolerance.
	// Check for positive slippage, just in case.
	function _enforceSlippageOut(uint256 _intended, uint256 _actual) internal view {
		uint256 exitSlipped = _intended > _actual ? _intended.sub(_actual) : 0;
		uint256 maxLoss = _intended.mul(maxSlippageOut).div(basisOne);
		require(exitSlipped <= maxLoss, "Slipped Out!");
	}

	function _giveAllowanceRouter() internal {
		rewardToken.safeApprove(address(router), 0);
		rewardToken.safeApprove(address(router), MAX);
	}

	function _giveAllowances() internal {
		want.safeApprove(address(stargateRouter), 0);
		want.safeApprove(address(stargateRouter), MAX);

		IERC20(address(lpToken)).safeApprove(address(masterChef), 0);
		IERC20(address(lpToken)).safeApprove(address(masterChef), MAX);

		_giveAllowanceRouter();
	}

	// Manually returns lps in masterChef to the strategy. Used in emergencies.
	function emergencyWithdrawFromMasterChef() external onlyVaultManagers {
		_withdrawFromMasterChefAndTransfer(address(this));
	}

	function _withdrawFromMasterChefAndTransfer(address _to) internal {
		if (abandonRewards) {
			masterChef.emergencyWithdraw(masterChefPoolId);
		} else {
			_claimRewards();
			_withdrawFromMasterChef();
			if (balanceOfReward() > 0) {
				IERC20(address(rewardToken)).safeTransfer(_to, balanceOfReward());
			}
		}
		uint256 _lpTokens = balanceOfLpTokens();
		if (_lpTokens > 0) {
			IERC20(address(lpToken)).safeTransfer(_to, _lpTokens);
		}
	}

	//--------------------------//
	// 	        Setters 		//
	//--------------------------//

	function setParams(uint256 _maxSlippageIn, uint256 _maxSlippageOut)
		public
		onlyVaultManagers
	{
		require(_maxSlippageIn <= basisOne);
		maxSlippageIn = _maxSlippageIn;

		require(_maxSlippageOut <= basisOne);
		maxSlippageOut = _maxSlippageOut;
	}

	function setDust(uint256 _rewardsDust, uint256 _wantDust) public onlyVaultManagers {
		wantDust = _wantDust;
		rewardsDust = _rewardsDust;
	}

	function setCollectFeesEnabled(bool _collectFeesEnabled) external onlyVaultManagers {
		collectFeesEnabled = _collectFeesEnabled;
	}

	// Toggle for whether to abandon rewards or not on emergency withdraws from masterChef.
	function setAbandonRewards(bool abandon) external onlyVaultManagers {
		abandonRewards = abandon;
	}

	function protectedTokens() internal view override returns (address[] memory) {
		// Want is already protected by default, rewardToken is omitted
		address[] memory protected = new address[](1);
		protected[0] = address(lpToken);

		return protected;
	}

	// Use this to determine when to harvest
	function harvestTrigger(uint256 callCostInWei) public view override returns (bool) {
		StrategyParams memory params = vault.strategies(address(this));

		// Should not trigger if strategy is not active (no assets and no debtRatio)
		if (!isActive()) return false;

		// Trigger if profit generated is higher than minProfit
		if (estimatedHarvest() > minProfit) return true;

		// Harvest no matter what once we reach our maxDelay
		if (block.timestamp.sub(params.lastReport) > maxReportDelay) return true;

		// Trigger if we want to manually harvest, but only if our gas price is acceptable
		if (forceHarvestTriggerOnce) return true;

		// Otherwise, we don't harvest
		return false;
	}

	function setMinProfit(uint256 _minAcceptableProfit) external onlyKeepers {
		minProfit = _minAcceptableProfit;
	}

	// This allows us to manually harvest with our keeper as needed.
	function setForceHarvestTriggerOnce(bool _forceHarvestTriggerOnce) external onlyKeepers {
		forceHarvestTriggerOnce = _forceHarvestTriggerOnce;
	}

	function tendTrigger(uint256 callCostInWei) public view override returns (bool) {
		return balanceOfWant() > 0;
	}

	function ethToWant(uint256 _amtInWei) public view override returns (uint256) {}

	receive() external payable {}
}