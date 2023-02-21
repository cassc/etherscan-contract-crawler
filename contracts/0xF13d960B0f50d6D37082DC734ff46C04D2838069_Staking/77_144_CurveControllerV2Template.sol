// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../interfaces/curve/ICryptoSwapPool.sol";
import "../../interfaces/curve/IRegistry.sol";
import "../../interfaces/curve/IAddressProvider.sol";
import "../BaseController.sol";

/* solhint-disable func-name-mixedcase, var-name-mixedcase */
contract CurveControllerV2Template is BaseController {
	event AddLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256 lp_token_amount
	);

	event RemoveLiquidity(
		address indexed provider,
		uint256[N_COINS] token_amounts,
		uint256 token_supply,
		uint256[N_COINS] amounts
	);

	event RemoveLiquidityOne(
		address indexed provider,
		uint256 token_amount,
		uint256 coin_index,
		uint256 coin_amount,
		address coin_address
	);

	using SafeERC20 for IERC20;
	using Address for address;
	using SafeMath for uint256;

	IAddressProvider public immutable addressProvider;

	uint256 public constant N_COINS = 2;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		IAddressProvider _curveAddressProvider
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(address(_curveAddressProvider) != address(0), "INVALID_CURVE_ADDRESS_PROVIDER");
		addressProvider = _curveAddressProvider;
	}

	/// @notice Deploy liquidity to Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amounts List of amounts of coins to deposit
	/// @param poolAddress Minimum amount of LP tokens to mint from the deposit
	function deploy(
		address poolAddress,
		uint256[N_COINS] calldata amounts,
		uint256 minMintAmount
	) external onlyManager onlyAddLiquidity {
		address lpTokenAddress = _getLPToken(poolAddress);
		uint256 amountsLength = amounts.length;

		for (uint256 i = 0; i < amountsLength; ++i) {
			if (amounts[i] > 0) {
				address coin = ICryptoSwapPool(poolAddress).coins(i);

				require(addressRegistry.checkAddress(coin, 0), "INVALID_COIN");

				uint256 balance = IERC20(coin).balanceOf(address(this));

				require(balance >= amounts[i], "INSUFFICIENT_BALANCE");

				_approve(IERC20(coin), poolAddress, amounts[i]);
			}
		}

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		ICryptoSwapPool(poolAddress).add_liquidity(amounts, minMintAmount);
		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));

		uint256 lpTokenAmount = lpTokenBalanceAfter.sub(lpTokenBalanceBefore);

		require(lpTokenAmount >= minMintAmount, "LP_AMT_TOO_LOW");

		emit AddLiquidity(msg.sender, amounts, IERC20(lpTokenAddress).totalSupply(), lpTokenAmount);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress Token addresses
	/// @param amount Quantity of LP tokens to burn in the withdrawal
	/// @param minAmounts Minimum amounts of underlying coins to receive
	function withdraw(
		address poolAddress,
		uint256 amount,
		uint256[N_COINS] memory minAmounts
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, amount);

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesBefore = _getCoinsBalances(poolAddress);

		ICryptoSwapPool(poolAddress).remove_liquidity(amount, minAmounts);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256[N_COINS] memory coinsBalancesAfter = _getCoinsBalances(poolAddress);

		_compareCoinsBalances(coinsBalancesBefore, coinsBalancesAfter, minAmounts);

		require(lpTokenBalanceBefore.sub(amount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		emit RemoveLiquidity(msg.sender, coinsBalancesAfter, IERC20(lpTokenAddress).totalSupply(), minAmounts);
	}

	/// @notice Withdraw liquidity from Curve pool
	/// @dev Calls to external contract
	/// @dev We trust sender to send a true curve poolAddress. If it's not the case it will fail in the add_liquidity part.
	/// @param poolAddress token addresses
	/// @param tokenAmount Amount of LP tokens to burn in the withdrawal
	/// @param i Index value of the coin to withdraw
	/// @param minAmount Minimum amount of coin to receive
	function withdrawOneCoin(
		address poolAddress,
		uint256 tokenAmount,
		uint256 i,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address lpTokenAddress = _getLPTokenAndApprove(poolAddress, tokenAmount);
		address coin = ICryptoSwapPool(poolAddress).coins(uint256(i));

		uint256 lpTokenBalanceBefore = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceBefore = IERC20(coin).balanceOf(address(this));

		ICryptoSwapPool(poolAddress).remove_liquidity_one_coin(tokenAmount, i, minAmount);

		uint256 lpTokenBalanceAfter = IERC20(lpTokenAddress).balanceOf(address(this));
		uint256 coinBalanceAfter = IERC20(coin).balanceOf(address(this));

		require(coinBalanceBefore < coinBalanceAfter, "BALANCE_MUST_INCREASE");
		require(lpTokenBalanceBefore.sub(tokenAmount) == lpTokenBalanceAfter, "LP_TOKEN_AMT_MISMATCH");

		uint256 coin_amount = ICryptoSwapPool(poolAddress).calc_withdraw_one_coin(minAmount, i);

		emit RemoveLiquidityOne(msg.sender, tokenAmount, i, coin_amount, coin);
	}

	function _getLPToken(address poolAddress) internal returns (address) {
		require(poolAddress != address(0), "INVALID_POOL_ADDRESS");

		address registryAddress = addressProvider.get_registry();
		address lpTokenAddress = IRegistry(registryAddress).get_lp_token(poolAddress);

		// If it's not registered in curve registry that should mean it's a factory pool (pool is also the LP Token)
		// https://curve.readthedocs.io/factory-pools.html?highlight=factory%20pools%20differ#lp-tokens
		if (lpTokenAddress == address(0)) {
			lpTokenAddress = poolAddress;
		}

		require(addressRegistry.checkAddress(lpTokenAddress, 0), "INVALID_LP_TOKEN");

		return lpTokenAddress;
	}

	function _getCoinsBalances(address poolAddress) internal returns (uint256[N_COINS] memory coinsBalances) {
		for (uint256 i = 0; i < N_COINS; ++i) {
			address coin = ICryptoSwapPool(poolAddress).coins(i);
			uint256 balance = IERC20(coin).balanceOf(address(this));
			coinsBalances[i] = balance;
		}
		return coinsBalances;
	}

	function _compareCoinsBalances(
		uint256[N_COINS] memory balancesBefore,
		uint256[N_COINS] memory balancesAfter,
		uint256[N_COINS] memory amounts
	) internal pure {
		for (uint256 i = 0; i < N_COINS; ++i) {
			uint256 minAmount = amounts[i];
			require(balancesAfter[i].sub(balancesBefore[i]) >= minAmount, "INVALID_BALANCE_CHANGE");
		}
	}

	function _getLPTokenAndApprove(address poolAddress, uint256 amount) internal returns (address) {
		address lpTokenAddress = _getLPToken(poolAddress);
		if (lpTokenAddress != poolAddress) {
			_approve(IERC20(lpTokenAddress), poolAddress, amount);
		}
		return lpTokenAddress;
	}

	function _approve(IERC20 token, address spender, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}