// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ICollateral, IPoolToken, IBorrowable, ImpermaxChef } from "../../interfaces/imx/IImpermax.sol";
import { HarvestSwapParams, IIMXFarm, IERC20, SafeERC20, IUniswapV2Pair, IUniswapV2Router01 } from "../mixins/IIMXFarm.sol";
import { UniUtils } from "../../libraries/UniUtils.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { CallType, CalleeData, AddLiquidityAndMintCalldata, BorrowBCalldata, RemoveLiqAndRepayCalldata } from "../../interfaces/Structs.sol";

// import "hardhat/console.sol";

abstract contract IMXFarm is IIMXFarm {
	using SafeERC20 for IERC20;
	using UniUtils for IUniswapV2Pair;
	// using FixedPointMathLib for uint256;

	IUniswapV2Pair public _pair;
	ICollateral private _collateralToken;
	IBorrowable private _uBorrowable;
	IBorrowable private _sBorrowable;
	IPoolToken private stakedToken;
	ImpermaxChef private _impermaxChef;

	IERC20 private _farmToken;
	IUniswapV2Router01 private _farmRouter;

	bool public flip;

	constructor(
		address underlying_,
		address pair_,
		address collateralToken_,
		address farmRouter_,
		address farmToken_
	) {
		_pair = IUniswapV2Pair(pair_);
		_collateralToken = ICollateral(collateralToken_);
		_uBorrowable = IBorrowable(_collateralToken.borrowable0());
		_sBorrowable = IBorrowable(_collateralToken.borrowable1());

		if (underlying_ != _uBorrowable.underlying()) {
			flip = true;
			(_uBorrowable, _sBorrowable) = (_sBorrowable, _uBorrowable);
		}
		stakedToken = IPoolToken(_collateralToken.underlying());
		_impermaxChef = ImpermaxChef(_uBorrowable.borrowTracker());
		_farmToken = IERC20(farmToken_);
		_farmRouter = IUniswapV2Router01(farmRouter_);

		// necessary farm approvals
		_farmToken.safeApprove(address(farmRouter_), type(uint256).max);
	}

	function impermaxChef() public view override returns (ImpermaxChef) {
		return _impermaxChef;
	}

	function collateralToken() public view override returns (ICollateral) {
		return _collateralToken;
	}

	function sBorrowable() public view override returns (IBorrowable) {
		return _sBorrowable;
	}

	function uBorrowable() public view override returns (IBorrowable) {
		return _uBorrowable;
	}

	function farmRouter() public view override returns (IUniswapV2Router01) {
		return _farmRouter;
	}

	function pair() public view override returns (IUniswapV2Pair) {
		return _pair;
	}

	function _addIMXLiquidity(
		uint256 underlyingAmnt,
		uint256 shortAmnt,
		uint256 uBorrow,
		uint256 sBorrow
	) internal virtual override {
		_sBorrowable.borrowApprove(address(_sBorrowable), sBorrow);

		// mint collateral
		bytes memory addLPData = abi.encode(
			CalleeData({
				callType: CallType.ADD_LIQUIDITY_AND_MINT,
				data: abi.encode(
					AddLiquidityAndMintCalldata({ uAmnt: underlyingAmnt, sAmnt: shortAmnt })
				)
			})
		);

		// borrow short data
		bytes memory borrowSData = abi.encode(
			CalleeData({
				callType: CallType.BORROWB,
				data: abi.encode(BorrowBCalldata({ borrowAmount: uBorrow, data: addLPData }))
			})
		);

		// flashloan borrow then add lp
		_sBorrowable.borrow(address(this), address(this), sBorrow, borrowSData);
	}

	function impermaxBorrow(
		address,
		address,
		uint256,
		bytes calldata data
	) public {
		// ensure that msg.sender is correct
		require(
			msg.sender == address(_sBorrowable) || msg.sender == address(_uBorrowable),
			"IMXFarm: NOT_BORROWABLE"
		);
		CalleeData memory calleeData = abi.decode(data, (CalleeData));

		if (calleeData.callType == CallType.ADD_LIQUIDITY_AND_MINT) {
			AddLiquidityAndMintCalldata memory d = abi.decode(
				calleeData.data,
				(AddLiquidityAndMintCalldata)
			);
			_addLp(d.uAmnt, d.sAmnt);
		} else if (calleeData.callType == CallType.BORROWB) {
			BorrowBCalldata memory d = abi.decode(calleeData.data, (BorrowBCalldata));
			_uBorrowable.borrow(address(this), address(this), d.borrowAmount, d.data);
		}
	}

	function _addLp(uint256 uAmnt, uint256 sAmnt) internal {
		{
			uint256 sBalance = short().balanceOf(address(this));
			uint256 uBalance = underlying().balanceOf(address(this));

			// TODO use swap fee to get exact amount out
			// if we have extra short tokens, trade them for underlying
			if (sBalance > sAmnt) {
				uBalance += pair()._swapExactTokensForTokens(
					sBalance - sAmnt,
					address(short()),
					address(underlying())
				);
				// sBalance = sAmnt now
			} else if (sAmnt > sBalance) {
				// when rebalancing we will never have more sAmnt than sBalance
				uBalance -= pair()._swapTokensForExactTokens(
					sAmnt - sBalance,
					address(underlying()),
					address(short())
				);
			}

			// we know that now our short balance is now exact sBalance = sAmnt
			// if we don't have enough underlying, we need to decrase sAmnt slighlty
			if (uBalance < uAmnt) {
				uAmnt = uBalance;
				uint256 sAmntNew = _underlyingToShort(uAmnt);
				// make sure we're not increaseing the amount
				if (sAmnt > sAmntNew) sAmnt = sAmntNew;
				else uAmnt = _shortToUnderlying(sAmnt);
			}
			if (uBalance > uAmnt) {
				// if we have extra underlying return to borrowable
				// TODO check that this gets accounted for
				underlying().safeTransfer(address(_uBorrowable), uBalance - uAmnt);
			}
		}

		underlying().safeTransfer(address(_pair), uAmnt);
		short().safeTransfer(address(_pair), sAmnt);

		uint256 liquidity = _pair.mint(address(this));

		// first we create staked token, then collateral token
		IERC20(address(_pair)).safeTransfer(address(stakedToken), liquidity);
		stakedToken.mint(address(_collateralToken));
		_collateralToken.mint(address(this));
	}

	function _removeIMXLiquidity(
		uint256 removeLpAmnt,
		uint256 repayUnderlying,
		uint256 repayShort,
		uint256 borrowUnderlying
	) internal override {
		uint256 redeemAmount = (removeLpAmnt * 1e18) / stakedToken.exchangeRate() + 1;

		bytes memory data = abi.encode(
			RemoveLiqAndRepayCalldata({
				removeLpAmnt: removeLpAmnt,
				repayUnderlying: repayUnderlying,
				repayShort: repayShort,
				borrowUnderlying: borrowUnderlying
			})
		);

		_collateralToken.flashRedeem(address(this), redeemAmount, data);
	}

	function impermaxRedeem(
		address,
		uint256 redeemAmount,
		bytes calldata data
	) public {
		require(msg.sender == address(_collateralToken), "IMXFarm: NOT_COLLATERAL");

		RemoveLiqAndRepayCalldata memory d = abi.decode(data, (RemoveLiqAndRepayCalldata));

		// redeem withdrawn staked coins
		IERC20(address(stakedToken)).safeTransfer(address(stakedToken), redeemAmount);
		stakedToken.redeem(address(this));

		// remove collateral
		(, uint256 shortAmnt) = _removeLiquidity(d.removeLpAmnt);

		// in some cases we need to borrow extra underlying
		if (d.borrowUnderlying > 0)
			_uBorrowable.borrow(address(this), address(this), d.borrowUnderlying, "");

		// trade extra tokens

		// if we have extra short tokens, trade them for underlying
		if (shortAmnt > d.repayShort) {
			// TODO edge case - not enough underlying?
			pair()._swapExactTokensForTokens(
				shortAmnt - d.repayShort,
				address(short()),
				address(underlying())
			);
			shortAmnt = d.repayShort;
		}
		// if we know the exact amount of short we must repay, then ensure we have that amount
		else if (shortAmnt < d.repayShort && d.repayShort != type(uint256).max) {
			uint256 amountOut = d.repayShort - shortAmnt;
			uint256 amountIn = pair()._getAmountIn(
				amountOut,
				address(underlying()),
				address(short())
			);
			uint256 inTokenBalance = underlying().balanceOf(address(this));
			if (amountIn > inTokenBalance) {
				shortAmnt += pair()._swapExactTokensForTokens(
					inTokenBalance,
					address(underlying()),
					address(short())
				);
			} else {
				pair()._swap(amountIn, amountOut, address(underlying()), address(short()));
				shortAmnt = d.repayShort;
			}
		}

		uint256 uBalance = underlying().balanceOf(address(this));

		// repay short loan
		short().safeTransfer(address(_sBorrowable), shortAmnt);
		_sBorrowable.borrow(address(this), address(0), 0, new bytes(0));

		// repay underlying loan
		if (uBalance > 0) {
			underlying().safeTransfer(
				address(_uBorrowable),
				d.repayUnderlying > uBalance ? uBalance : d.repayUnderlying
			);
			_uBorrowable.borrow(address(this), address(0), 0, new bytes(0));
		}

		uint256 cAmount = (redeemAmount * 1e18) / _collateralToken.exchangeRate() + 1;

		// uint256 colBal = _collateralToken.balanceOf(address(this));
		// TODO add tests to make ensure cAmount < colBal

		// return collateral token
		IERC20(address(_collateralToken)).safeTransfer(
			address(_collateralToken),
			// colBal < cAmount ? colBal : cAmount
			cAmount
		);
	}

	function pendingHarvest() external view override returns (uint256 harvested) {
		if (address(_impermaxChef) == address(0)) return 0;
		harvested =
			_impermaxChef.pendingReward(address(_sBorrowable), address(this)) +
			_impermaxChef.pendingReward(address(_uBorrowable), address(this));
	}

	function harvestIsEnabled() public view returns (bool) {
		return address(_impermaxChef) != address(0);
	}

	function _harvestFarm(HarvestSwapParams calldata harvestParams)
		internal
		override
		returns (uint256 harvested, uint256 amountOut)
	{
		// rewards are not enabled
		if (address(_impermaxChef) == address(0)) return (harvested, amountOut);
		address[] memory borrowables = new address[](2);
		borrowables[0] = address(_sBorrowable);
		borrowables[1] = address(_uBorrowable);

		_impermaxChef.massHarvest(borrowables, address(this));

		harvested = _farmToken.balanceOf(address(this));
		if (harvested == 0) return (harvested, amountOut);

		uint256[] memory amounts = _swap(
			_farmRouter,
			harvestParams,
			address(_farmToken),
			harvested
		);
		amountOut = amounts[amounts.length - 1];
		emit HarvestedToken(address(_farmToken), harvested);
	}

	function _getLiquidity() internal view override returns (uint256) {
		return _getLiquidity(_collateralToken.balanceOf(address(this)));
	}

	function _getLiquidity(uint256 balance) internal view override returns (uint256) {
		if (balance == 0) return 0;
		return
			(stakedToken.exchangeRate() * (_collateralToken.exchangeRate() * (balance - 1))) /
			1e18 /
			1e18;
	}

	function _getBorrowBalances() internal view override returns (uint256, uint256) {
		return (
			_uBorrowable.borrowBalance(address(this)),
			_sBorrowable.borrowBalance(address(this))
		);
	}

	function accrueInterest() public override {
		_sBorrowable.accrueInterest();
		_uBorrowable.accrueInterest();
	}

	function _updateAndGetBorrowBalances() internal override returns (uint256, uint256) {
		accrueInterest();
		return _getBorrowBalances();
	}

	/// @notice borrow amount of underlying for every 1e18 of deposit
	/// @dev currently cannot go below ~2.02x lev
	function _optimalUBorrow() internal view override returns (uint256 uBorrow) {
		uint256 l = _collateralToken.liquidationIncentive();
		// this is the adjusted safety margin - how far we stay from liquidation
		uint256 s = (_collateralToken.safetyMarginSqrt() * safetyMarginSqrt()) / 1e18;
		uBorrow = (1e18 * (2e18 - (l * s) / 1e18)) / ((l * 1e18) / s + (l * s) / 1e18 - 2e18);
	}

	function loanHealth() public view override returns (uint256) {
		// this updates the oracle
		uint256 balance = IERC20(address(_collateralToken)).balanceOf(address(this));
		if (balance == 0) return 100e18;
		uint256 liq = (balance * _collateralToken.exchangeRate()) / 1e18;
		(uint256 available, uint256 shortfall) = _collateralToken.accountLiquidity(address(this));
		if (liq < shortfall) return 0; // we are way past liquidation
		return shortfall == 0 ? (1e18 * (liq + available)) / liq : (1e18 * (liq - shortfall)) / liq;
	}

	function shortToUnderlyingOracleUpdate(uint256 amount) public override returns (uint256) {
		(bool success, bytes memory data) = address(collateralToken()).call(
			abi.encodeWithSignature("getPrices()")
		);
		if (!success) revert OracleUpdate();
		(uint256 price0, uint256 price1) = abi.decode(data, (uint256, uint256));
		return flip ? (amount * price0) / price1 : (amount * price1) / price0;
	}

	function shortToUnderlyingOracle(uint256 amount) public view override returns (uint256) {
		try collateralToken().getPrices() returns (uint256 price0, uint256 price1) {
			return flip ? (amount * price0) / price1 : (amount * price1) / price0;
		} catch {
			revert OracleUpdate();
		}
	}

	error OracleUpdate();
}