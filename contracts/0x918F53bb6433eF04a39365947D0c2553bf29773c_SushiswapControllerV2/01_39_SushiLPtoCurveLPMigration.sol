// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/curve/ICryptoSwapPool.sol";
import "../../interfaces/IAddressRegistry.sol";
import "../../interfaces/ISushiLPtoCurveLPMigration.sol";

contract SushiLPtoCurveLPMigration is ISushiLPtoCurveLPMigration {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	IAddressRegistry public immutable addressRegistry;

	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Router02 public immutable SUSHISWAP_ROUTER;
	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Pair public immutable SUSHI_PAIR;
	// solhint-disable-next-line var-name-mixedcase
	ICryptoSwapPool public immutable CURVE_POOL;
	// solhint-disable-next-line var-name-mixedcase
	IERC20 public immutable CURVE_LP_TOKEN;
	// solhint-disable-next-line var-name-mixedcase
	IERC20 public immutable TOKE;
	// solhint-disable-next-line var-name-mixedcase
	IERC20 public immutable WETH;

	constructor(
		IUniswapV2Router02 _sushiRouter,
		IUniswapV2Pair _sushiPair,
		IERC20 _toke,
		IERC20 _weth,
		address _curvePool,
		address _curveLpToken,
		address _addressRegistry
	) public {
		require(address(_sushiRouter) != address(0), "INVALID_ROUTER");
		require(address(_sushiPair) != address(0), "INVALID_SUSHI_PAIR");
		require(address(_toke) != address(0), "INVALID_TOKE");
		require(address(_weth) != address(0), "INVALID_WETH");
		require(_curvePool != address(0), "INVALID_CURVEPOOL");
		require(_curveLpToken != address(0), "INVALID_CURVELPTOKEN");
		require(_addressRegistry != address(0), "INVALID_REGISTRY_ADDRESS");

		require(ICryptoSwapPool(_curvePool).coins(0) == address(_weth), "INVALID_CURVE_POOL_WETH");
		require(ICryptoSwapPool(_curvePool).coins(1) == address(_toke), "INVALID_CURVE_POOL_TOKE");
		require(IUniswapV2Pair(_sushiPair).token0() == address(_toke), "INVALID_SUSHI_POOL_TOKE");
		require(IUniswapV2Pair(_sushiPair).token1() == address(_weth), "INVALID_SUSHI_POOL_WETH");

		addressRegistry = IAddressRegistry(_addressRegistry);

		SUSHI_PAIR = _sushiPair;
		TOKE = _toke;
		WETH = _weth;

		CURVE_POOL = ICryptoSwapPool(_curvePool);
		CURVE_LP_TOKEN = IERC20(_curveLpToken);

		SUSHISWAP_ROUTER = _sushiRouter;
	}

	function migrate(
		SushiWithdrawalInfo calldata withdrawalInfo,
		uint256 amountCurveLpMin,
		address to
	) external override {
		(uint256 amountTokeReceived, uint256 amountWethReceived) = _withdrawFromSushi(
			withdrawalInfo.amountLp,
			withdrawalInfo.amountTokeMin,
			withdrawalInfo.amountWethMin,
			address(this),
			withdrawalInfo.deadline
		);

		uint256 amountLpMinted = _deploytoCurve(amountTokeReceived, amountWethReceived, amountCurveLpMin);

		CURVE_LP_TOKEN.safeTransfer(to, amountLpMinted);

		emit SushiLPtoCurveLPMigrationEvent(
			withdrawalInfo.amountLp,
			amountLpMinted,
			amountTokeReceived,
			amountWethReceived
		);
	}

	/// @notice Withdraw liquidity from a sushiswap LP pool
	/// @param amountLp Amount of liquidity tokens to remove from pool
	/// @param amountTokeMin Minimum amount of TOKE to receive
	/// @param amountWethMin Minimum amount of WETH to receive
	/// @param to Address to send received tokens to
	/// @param deadline Unix timestamp denoting time tx must execute by
	function _withdrawFromSushi(
		uint256 amountLp,
		uint256 amountTokeMin,
		uint256 amountWethMin,
		address to,
		uint256 deadline
	) internal returns (uint256 amountTokeReceived, uint256 amountWethReceived) {
		require(SUSHI_PAIR.balanceOf(address(this)) >= amountLp, "INSUFFICIENT_LIQUIDITY");
		_approve(address(SUSHISWAP_ROUTER), IERC20(address(SUSHI_PAIR)), amountLp);

		uint256 tokeBalanceBeforeLiquidityRemoval = TOKE.balanceOf(address(this));
		uint256 wethBalanceBeforeLiquidityRemoval = WETH.balanceOf(address(this));

		SUSHISWAP_ROUTER.removeLiquidity(
			address(TOKE),
			address(WETH),
			amountLp,
			amountTokeMin,
			amountWethMin,
			to,
			deadline
		);

		uint256 tokeBalanceAfterLiquidityRemoval = TOKE.balanceOf(address(this));
		uint256 wethBalanceAfterLiquidityRemoval = WETH.balanceOf(address(this));

		amountTokeReceived = tokeBalanceAfterLiquidityRemoval.sub(tokeBalanceBeforeLiquidityRemoval);
		amountWethReceived = wethBalanceAfterLiquidityRemoval.sub(wethBalanceBeforeLiquidityRemoval);

		require(amountTokeReceived >= amountTokeMin, "MUST_BE_GREATER_THAN_MIN_TOKE");
		require(amountWethReceived >= amountWethMin, "MUST_BE_GREATER_THAN_MIN_WETH");
	}

	/// @notice Deploy liquidity to Curve pool
	/// @param amountToke Amount of TOKE to deposit
	/// @param amountWeth Amount of WETH to deposit
	/// @param amountLpMin Minimum amount of LP token to receive
	/// @return amountLpMinted amount of LP token received
	function _deploytoCurve(
		uint256 amountToke,
		uint256 amountWeth,
		uint256 amountLpMin
	) internal returns (uint256 amountLpMinted) {
		uint256 wethBalance = WETH.balanceOf(address(this));
		uint256 tokeBalance = TOKE.balanceOf(address(this));

		require(wethBalance >= amountWeth, "INSUFFICIENT_BALANCE");
		require(tokeBalance >= amountToke, "INSUFFICIENT_BALANCE");
		
		_approve(address(CURVE_POOL), WETH, amountWeth);
		_approve(address(CURVE_POOL), TOKE, amountToke);

		uint256 lpTokenBalanceBefore = CURVE_LP_TOKEN.balanceOf(address(this));
		CURVE_POOL.add_liquidity([amountWeth, amountToke], amountLpMin);
		uint256 lpTokenBalanceAfter = CURVE_LP_TOKEN.balanceOf(address(this));

		amountLpMinted = lpTokenBalanceAfter.sub(lpTokenBalanceBefore);

		require(amountLpMinted >= amountLpMin, "LP_AMT_TOO_LOW");
	}

	function _approve(
		address spender,
		IERC20 token,
		uint256 amount
	) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}