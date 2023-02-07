// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IBase, HarvestSwapParams } from "../mixins/IBase.sol";
import { IIMXFarm } from "../mixins/IIMXFarm.sol";
import { UniUtils, IUniswapV2Pair } from "../../libraries/UniUtils.sol";
import { FixedPointMathLib } from "../../libraries/FixedPointMathLib.sol";
import { ISimpleUniswapOracle } from "../../interfaces/uniswap/ISimpleUniswapOracle.sol";

import { StratAuth } from "../../common/StratAuth.sol";
import { ISCYStrategy } from "../../interfaces/ERC5115/ISCYStrategy.sol";

// import "hardhat/console.sol";

abstract contract IMXCore is ReentrancyGuard, StratAuth, IBase, IIMXFarm, ISCYStrategy {
	using FixedPointMathLib for uint256;
	using UniUtils for IUniswapV2Pair;
	using SafeERC20 for IERC20;

	event Deposit(address sender, uint256 amount);
	event Redeem(address sender, uint256 amount);

	// event RebalanceLoan(address indexed sender, uint256 startLoanHealth, uint256 updatedLoanHealth);
	event SetRebalanceThreshold(uint256 rebalanceThreshold);
	// this determines our default leverage position
	event SetSafetyMarginSqrt(uint256 safetyMarginSqrt);

	event Harvest(uint256 harvested); // this is actual the tvl before harvest
	event Rebalance(uint256 shortPrice, uint256 tvlBeforeRebalance, uint256 positionOffset);
	event SetMaxPriceOffset(uint256 maxPriceOffset);

	uint256 constant MINIMUM_LIQUIDITY = 1000;
	uint256 constant BPS_ADJUST = 10000;

	IERC20 private _underlying;
	IERC20 private _short;

	uint16 public rebalanceThreshold = 400; // 4% of lp
	// price move before liquidation
	uint256 private _safetyMarginSqrt = 1.140175425e18; // sqrt of 130%
	uint256 public maxPriceOffset = .2e18;

	modifier checkPrice(uint256 expectedPrice, uint256 maxDelta) {
		// parameter validation
		// to prevent manipulation by manager
		if (!hasRole(GUARDIAN, msg.sender)) {
			uint256 oraclePrice = shortToUnderlyingOracleUpdate(1e18);
			uint256 oracleDelta = oraclePrice > expectedPrice
				? oraclePrice - expectedPrice
				: expectedPrice - oraclePrice;
			if ((1e18 * (oracleDelta + maxDelta)) / expectedPrice > maxPriceOffset)
				revert OverMaxPriceOffset();
		}

		uint256 currentPrice = _shortToUnderlying(1e18);
		uint256 delta = expectedPrice > currentPrice
			? expectedPrice - currentPrice
			: currentPrice - expectedPrice;
		if (delta > maxDelta) revert SlippageExceeded();
		_;
	}

	constructor(
		address vault_,
		address underlying_,
		address short_
	) {
		vault = vault_;
		_underlying = IERC20(underlying_);
		_short = IERC20(short_);

		// _underlying.safeApprove(vault, type(uint256).max);

		// init default params
		// deployer is not owner so we set these manually

		// TODO param?
		rebalanceThreshold = 400;
		emit SetRebalanceThreshold(400);

		maxPriceOffset = .2e18;
		emit SetMaxPriceOffset(maxPriceOffset);

		_safetyMarginSqrt = 1.140175425e18;
		emit SetSafetyMarginSqrt(_safetyMarginSqrt);
	}

	// guardian can adjust max price offset if needed
	function setMaxPriceOffset(uint256 _maxPriceOffset) public onlyRole(GUARDIAN) {
		maxPriceOffset = _maxPriceOffset;
		emit SetMaxPriceOffset(_maxPriceOffset);
	}

	function safetyMarginSqrt() public view override returns (uint256) {
		return _safetyMarginSqrt;
	}

	function decimals() public view returns (uint8) {
		return IERC20Metadata(address(_underlying)).decimals();
	}

	// OWNER CONFIG

	function setRebalanceThreshold(uint16 rebalanceThreshold_) public onlyOwner {
		require(rebalanceThreshold_ >= 100, "STRAT: BAD_INPUT");
		rebalanceThreshold = rebalanceThreshold_;
		emit SetRebalanceThreshold(rebalanceThreshold_);
	}

	function setSafetyMarginSqrt(uint256 safetyMarginSqrt_) public onlyOwner {
		_safetyMarginSqrt = safetyMarginSqrt_;
		emit SetSafetyMarginSqrt(_safetyMarginSqrt);
	}

	// PUBLIC METHODS

	function short() public view override returns (IERC20) {
		return _short;
	}

	function underlying() public view virtual override(IBase, ISCYStrategy) returns (IERC20) {
		return _underlying;
	}

	// deposit underlying and recieve lp tokens
	function deposit(uint256 underlyingAmnt) external onlyVault nonReentrant returns (uint256) {
		if (underlyingAmnt == 0) return 0; // cannot deposit 0
		uint256 startBalance = collateralToken().balanceOf(address(this));
		_increasePosition(underlyingAmnt);
		uint256 endBalance = collateralToken().balanceOf(address(this));
		return endBalance - startBalance;
	}

	// redeem lp for underlying
	function redeem(address recipient, uint256 removeCollateral)
		public
		onlyVault
		returns (uint256 amountTokenOut)
	{
		if (removeCollateral < MINIMUM_LIQUIDITY) return 0; // cannot redeem 0
		// this is the full amount of LP tokens totalSupply of shares is entitled to
		_decreasePosition(removeCollateral);

		// make sure we never have any extra underlying dust sitting around
		// all 'extra' underlying should allways be transferred back to the vault

		unchecked {
			amountTokenOut = _underlying.balanceOf(address(this));
		}
		_underlying.safeTransfer(recipient, amountTokenOut);
		emit Redeem(msg.sender, amountTokenOut);
	}

	/// @notice decreases position based to desired LP amount
	/// @dev ** does not rebalance remaining portfolio
	/// @param removeCollateral amount of callateral token to remove
	function _decreasePosition(uint256 removeCollateral) internal {
		(uint256 uBorrowBalance, uint256 sBorrowBalance) = _updateAndGetBorrowBalances();

		uint256 balance = collateralToken().balanceOf(address(this));
		uint256 lp = _getLiquidity(balance);

		// remove lp & repay underlying loan
		// round up to avoid under-repaying
		uint256 removeLp = lp.mulDivUp(removeCollateral, balance);
		uint256 uRepay = uBorrowBalance.mulDivUp(removeCollateral, balance);
		uint256 sRepay = sBorrowBalance.mulDivUp(removeCollateral, balance);

		_removeIMXLiquidity(removeLp, uRepay, sRepay, 0);
	}

	// increases the position based on current desired balance
	// ** does not rebalance remaining portfolio
	function _increasePosition(uint256 amntUnderlying) internal {
		if (amntUnderlying < MINIMUM_LIQUIDITY) return; // avoid imprecision
		(uint256 uLp, uint256 sLp) = _getLPBalances();
		(uint256 uBorrowBalance, uint256 sBorrowBalance) = _getBorrowBalances();

		uint256 tvl = getAndUpdateTvl() - amntUnderlying;

		uint256 uBorrow;
		uint256 sBorrow;
		uint256 uAddLp;
		uint256 sAddLp;

		// on initial deposit or if amount are below threshold for accurate accounting
		if (
			tvl < MINIMUM_LIQUIDITY ||
			uLp < MINIMUM_LIQUIDITY ||
			sLp < MINIMUM_LIQUIDITY ||
			uBorrowBalance < MINIMUM_LIQUIDITY ||
			sBorrowBalance < MINIMUM_LIQUIDITY
		) {
			uBorrow = (_optimalUBorrow() * amntUnderlying) / 1e18;
			uAddLp = amntUnderlying + uBorrow;
			sBorrow = _underlyingToShort(uAddLp);
			sAddLp = sBorrow;
		} else {
			// if tvl > 0 we need to keep the exact proportions of current position
			// to ensure we have correct accounting independent of price moves
			uBorrow = (uBorrowBalance * amntUnderlying) / tvl;
			uAddLp = (uLp * amntUnderlying) / tvl;
			sBorrow = (sBorrowBalance * amntUnderlying) / tvl;
			sAddLp = _underlyingToShort(uAddLp);
		}

		_addIMXLiquidity(uAddLp, sAddLp, uBorrow, sBorrow);
	}

	// use the return of the function to estimate pending harvest via staticCall
	function harvest(HarvestSwapParams[] calldata harvestParams, HarvestSwapParams[] calldata)
		external
		onlyVault
		nonReentrant
		returns (uint256[] memory farmHarvest, uint256[] memory)
	{
		(uint256 startTvl, , , , , ) = getTVL();

		farmHarvest = new uint256[](1);
		// return amount of underlying tokens harvested
		(, farmHarvest[0]) = _harvestFarm(harvestParams[0]);

		// compound our lp position
		_increasePosition(_underlying.balanceOf(address(this)));
		emit Harvest(startTvl);
		return (farmHarvest, new uint256[](0));
	}

	function rebalance(uint256 expectedPrice, uint256 maxDelta)
		external
		onlyRole(MANAGER)
		checkPrice(expectedPrice, maxDelta)
		nonReentrant
	{
		// call this first to ensure we use an updated borrowBalance when computing offset
		uint256 tvl = getAndUpdateTvl();
		uint256 positionOffset = getPositionOffset();

		// don't rebalance unless we exceeded the threshold
		// GUARDIAN can execute rebalance any time
		if (positionOffset <= rebalanceThreshold && !hasRole(GUARDIAN, msg.sender))
			revert RebalanceThreshold();

		if (tvl == 0) return;
		uint256 targetUBorrow = (tvl * _optimalUBorrow()) / 1e18;
		uint256 targetUnderlyingLP = tvl + targetUBorrow;

		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 targetShortLp = _underlyingToShort(targetUnderlyingLP);
		(uint256 uBorrowBalance, uint256 sBorrowBalance) = _updateAndGetBorrowBalances();

		// TODO account for uBalance?
		// uint256 uBalance = underlying().balanceOf(address(this));

		if (underlyingLp > targetUnderlyingLP) {
			uint256 uRepay;
			uint256 uBorrow;
			if (uBorrowBalance > targetUBorrow) uRepay = uBorrowBalance - targetUBorrow;
			else uBorrow = targetUBorrow - uBorrowBalance;

			uint256 sRepay = sBorrowBalance > targetShortLp ? sBorrowBalance - targetShortLp : 0;

			uint256 lp = _getLiquidity();
			uint256 removeLp = lp - (lp * targetUnderlyingLP) / underlyingLp;
			_removeIMXLiquidity(removeLp, uRepay, sRepay, uBorrow);
		} else if (targetUnderlyingLP > underlyingLp) {
			uint256 uBorrow = targetUBorrow > uBorrowBalance ? targetUBorrow - uBorrowBalance : 0;
			uint256 sBorrow = targetShortLp > sBorrowBalance ? targetShortLp - sBorrowBalance : 0;

			uint256 uAdd = targetUnderlyingLP - underlyingLp;

			// extra underlying balance will get re-paid automatically
			_addIMXLiquidity(
				uAdd,
				_underlyingToShort(uAdd), // this is more precise than targetShortLp - shortLP because of rounding
				uBorrow,
				sBorrow
			);
		}
		emit Rebalance(_shortToUnderlying(1e18), positionOffset, tvl);
	}

	// vault handles slippage
	function closePosition(uint256) public onlyVault returns (uint256 balance) {
		(uint256 uRepay, uint256 sRepay) = _updateAndGetBorrowBalances();
		uint256 removeLp = _getLiquidity();
		_removeIMXLiquidity(removeLp, uRepay, sRepay, 0);
		// transfer funds to vault
		balance = _underlying.balanceOf(address(this));
		_underlying.safeTransfer(vault, balance);
	}

	// TVL
	function getMaxTvl() public view returns (uint256) {
		(uint256 uBorrow, uint256 sBorrow) = _getBorrowBalances();
		uint256 sMax = sBorrowable().totalBalance();
		uint256 optimalBorrow = _optimalUBorrow();
		return
			// adjust the availableToBorrow to account for leverage
			min(
				((uBorrow + uBorrowable().totalBalance()) * 1e18) / optimalBorrow,
				_shortToUnderlying((sBorrow + sMax) * 1e18) / (optimalBorrow + 1e18)
			);
	}

	// TODO should we compute pending farm & lending rewards here?
	function getAndUpdateTvl() public returns (uint256 tvl) {
		(uint256 uBorrow, uint256 shortPosition) = _updateAndGetBorrowBalances();
		uint256 borrowBalance = _shortToUnderlying(shortPosition) + uBorrow;
		uint256 shortP = _short.balanceOf(address(this));
		uint256 shortBalance = shortP == 0
			? 0
			: _shortToUnderlying(_short.balanceOf(address(this)));
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 underlyingBalance = _underlying.balanceOf(address(this));
		uint256 assets = underlyingLp * 2 + underlyingBalance + shortBalance;
		tvl = assets > borrowBalance ? assets - borrowBalance : 0;
	}

	function getTotalTVL() public view returns (uint256 tvl) {
		(tvl, , , , , ) = getTVL();
	}

	function getTvl() public view returns (uint256 tvl) {
		(tvl, , , , , ) = getTVL();
	}

	function getTVL()
		public
		view
		returns (
			uint256 tvl,
			uint256,
			uint256 borrowPosition,
			uint256 borrowBalance,
			uint256 lpBalance,
			uint256 underlyingBalance
		)
	{
		uint256 underlyingBorrow;
		(underlyingBorrow, borrowPosition) = _getBorrowBalances();
		borrowBalance = _shortToUnderlying(borrowPosition) + underlyingBorrow;

		uint256 shortPosition = _short.balanceOf(address(this));
		uint256 shortBalance = shortPosition == 0 ? 0 : _shortToUnderlying(shortPosition);

		(uint256 underlyingLp, uint256 shortLp) = _getLPBalances();
		lpBalance = underlyingLp + _shortToUnderlying(shortLp);
		underlyingBalance = _underlying.balanceOf(address(this));
		uint256 assets = lpBalance + underlyingBalance + shortBalance;
		tvl = assets > borrowBalance ? assets - borrowBalance : 0;
	}

	function getPositionOffset() public view returns (uint256 positionOffset) {
		(, uint256 shortLp) = _getLPBalances();
		(, uint256 borrowBalance) = _getBorrowBalances();
		uint256 shortBalance = shortLp + _short.balanceOf(address(this));
		if (shortBalance == borrowBalance) return 0;
		// if short lp > 0 and borrowBalance is 0 we are off by inf, returning 100% should be enough
		if (borrowBalance == 0) return 10000;
		// this is the % by which our position has moved from beeing balanced

		positionOffset = shortBalance > borrowBalance
			? ((shortBalance - borrowBalance) * BPS_ADJUST) / borrowBalance
			: ((borrowBalance - shortBalance) * BPS_ADJUST) / borrowBalance;
	}

	// UTILS
	function getExpectedPrice() external view returns (uint256) {
		return _shortToUnderlying(1e18);
	}

	function getLPBalances() public view returns (uint256 underlyingLp, uint256 shortLp) {
		return _getLPBalances();
	}

	function getLiquidity() external view returns (uint256) {
		return _getLiquidity();
	}

	// used to estimate price of collateral token in underlying
	function collateralToUnderlying() public view returns (uint256) {
		(uint256 uR, uint256 sR, ) = pair().getReserves();
		(uR, sR) = address(_underlying) == pair().token0() ? (uR, sR) : (sR, uR);
		uint256 lp = pair().totalSupply();
		// for deposit of 1 underlying we get 1+_optimalUBorrow worth of lp -> collateral token
		return (1e18 * (uR * _getLiquidity(1e18))) / lp / (1e18 + _optimalUBorrow());
	}

	// in some cases the oracle needs to be updated externally
	// to be accessible by read methods like loanHealth();
	function updateOracle() public {
		try collateralToken().tarotPriceOracle() returns (address _oracle) {
			ISimpleUniswapOracle oracle = ISimpleUniswapOracle(_oracle);
			oracle.getResult(collateralToken().underlying());
		} catch {
			ISimpleUniswapOracle oracle = ISimpleUniswapOracle(
				collateralToken().simpleUniswapOracle()
			);
			oracle.getResult(collateralToken().underlying());
		}
	}

	function getLpToken() public view returns (address) {
		return address(collateralToken());
	}

	function getLpBalance() external view returns (uint256) {
		return collateralToken().balanceOf(address(this));
	}

	function getWithdrawAmnt(uint256 lpTokens) public view returns (uint256) {
		return (lpTokens * collateralToUnderlying()) / 1e18;
	}

	function getDepositAmnt(uint256 uAmnt) public view returns (uint256) {
		return (uAmnt * 1e18) / collateralToUnderlying();
	}

	/// @dev we can call this method via staticall to get the loan health
	/// even when oracle has not been updated
	function callLoanHealth() external returns (uint256) {
		updateOracle();
		return loanHealth();
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	error RebalanceThreshold();
	error LowLoanHealth();
	error SlippageExceeded();
	error OverMaxPriceOffset();
}