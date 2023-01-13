// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "../interfaces/sushiswap/IMasterChefV2.sol";
import "../interfaces/sushiswap/IComplexRewarder.sol";
import "./BaseController.sol";

contract SushiswapControllerV2 is BaseController {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Router02 public immutable SUSHISWAP_ROUTER;
	// solhint-disable-next-line var-name-mixedcase
	IUniswapV2Factory public immutable SUSHISWAP_FACTORY;
	// solhint-disable-next-line var-name-mixedcase
	IMasterChefV2 public immutable MASTERCHEF;
	// solhint-disable-next-line var-name-mixedcase
	address public immutable TREASURY;

	constructor(
		IUniswapV2Router02 router,
		IUniswapV2Factory factory,
		IMasterChefV2 masterchef,
		address manager,
		address accessControl,
		address addressRegistry,
		address treasury
	) public BaseController(manager, accessControl, addressRegistry) {
		require(address(router) != address(0), "INVALID_ROUTER");
		require(address(factory) != address(0), "INVALID_FACTORY");
		require(address(masterchef) != address(0), "INVALID_MASTERCHEF");
		require(treasury != address(0), "INVALID_TREASURY");
		SUSHISWAP_ROUTER = router;
		SUSHISWAP_FACTORY = factory;
		MASTERCHEF = masterchef;
		TREASURY = treasury;
	}

	/// @notice deploy liquidity to Sushiswap pool
	/// @dev Calls to external contract
	/// @param tokenA Address of one token in pair to be deposited as liquidity
	/// @param tokenB Address of other token in pair to be deposited as liquidity
	/// @param amountADesired Desired amount of tokenA to add as liquidity
	/// @param amountBDesired Desired amount of tokenB to add as liquidity
	/// @param amountAMin Minimum amount of tokenA to add as liquidity
	/// @param amountBMin Minimum amount of tokenB to add as liquidity
	/// @param to Recipient of liquidity tokens
	/// @param deadline Unix timestamp after which tx will revert
	/// @param poolId Id of pool for Masterchef lp deposits
	/// @param toDeposit Bool to deposit lp tokens into Masterchef contract or not
	/// @param toDepositAll Bool to deposit extraneous lp tokens
	function deploy(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		uint256 poolId,
		bool toDeposit,
		bool toDepositAll
	) external onlyManager onlyAddLiquidity {
		require(to == manager, "MUST_BE_MANAGER");
		require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
		require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

		_approve(address(SUSHISWAP_ROUTER), IERC20(tokenA), amountADesired);
		_approve(address(SUSHISWAP_ROUTER), IERC20(tokenB), amountBDesired);

		IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
		require(address(pair) != address(0), "NONEXISTENT_PAIR");
		uint256 balanceBefore = pair.balanceOf(address(this));

		(, , uint256 liquidity) = SUSHISWAP_ROUTER.addLiquidity(
			tokenA,
			tokenB,
			amountADesired,
			amountBDesired,
			amountAMin,
			amountBMin,
			to,
			deadline
		);

		uint256 balanceAfter = pair.balanceOf(address(this));
		require(balanceAfter > balanceBefore, "MUST_INCREASE");

		if (toDeposit) {
			(IERC20[] memory rewardTokens, uint256[] memory rewards) = _checkRewards(poolId);
			if (toDepositAll) {
				liquidity = pair.balanceOf(address(this));
			}
			_approve(address(MASTERCHEF), pair, liquidity);
			_depositLPTokensToMasterChef(poolId, liquidity);
			_transferMasterchefRewards(rewardTokens, rewards);
		}
	}

	/// @notice Withdraw liquidity from a sushiswap LP pool
	/// @dev Calls an external contract
	/// @param tokenA Address of one token in pair to be withdraw from pool
	/// @param tokenB Address of other token in pair to be withdrawn from pool
	/// @param liquidity Amount of liquidity tokens to remove from pool
	/// @param amountAMin Minimum amount of tokenA to receive
	/// @param amountBMin Minimum amount of tokenB to receive
	/// @param to Address to send received tokens to
	/// @param deadline Unix timestamp denoting time tx must execute by
	/// @param poolId Id of pool for withdrawal of LP tokens from Masterchef
	/// @param toWithdraw Bool to withdraw lp tokens from masterchef
	function withdraw(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		uint256 poolId,
		bool toWithdraw
	) external onlyManager onlyRemoveLiquidity {
		require(to == manager, "MUST_BE_MANAGER");
		require(addressRegistry.checkAddress(tokenA, 0), "INVALID_TOKEN");
		require(addressRegistry.checkAddress(tokenB, 0), "INVALID_TOKEN");

		IERC20 tokenAInterface = IERC20(tokenA);
		IERC20 tokenBInterface = IERC20(tokenB);

		IERC20 pair = IERC20(SUSHISWAP_FACTORY.getPair(tokenA, tokenB));
		require(address(pair) != address(0), "NONEXISTENT_PAIR");

		if (toWithdraw) {
			(IERC20[] memory rewardTokens, uint256[] memory rewards) = _checkRewards(poolId);
			bool withdrawalHappened = _withdrawLPTokensFromMasterChef(poolId, pair.balanceOf(address(this)), liquidity);
			if (withdrawalHappened) {
				_transferMasterchefRewards(rewardTokens, rewards);
			}
		}

		require(pair.balanceOf(address(this)) >= liquidity, "INSUFFICIENT_LIQUIDITY");
		_approve(address(SUSHISWAP_ROUTER), pair, liquidity);

		uint256 tokenABalanceBeforeLiquidityRemoval = tokenAInterface.balanceOf(address(this));
		uint256 tokenBBalanceBeforeLiquidityRemoval = tokenBInterface.balanceOf(address(this));

		SUSHISWAP_ROUTER.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);

		uint256 tokenABalanceAfterLiquidityRemoval = tokenAInterface.balanceOf(address(this));
		uint256 tokenBBalanceAfterLiquidityRemoval = tokenBInterface.balanceOf(address(this));
		require(tokenABalanceAfterLiquidityRemoval > tokenABalanceBeforeLiquidityRemoval, "MUST_INCREASE");
		require(tokenBBalanceAfterLiquidityRemoval > tokenBBalanceBeforeLiquidityRemoval, "MUST_INCREASE");
	}

	/// @notice claims Sushi rewards from Masterchef contract
	/// @dev reverts if no sushi claimable
	function claimSushi(uint256 poolId) external onlyManager onlyMiscOperation {
		uint256 pendingSushi = MASTERCHEF.pendingSushi(poolId, address(this));
		require(pendingSushi > 0, "NO_CLAIMABLE");

		(IERC20[] memory rewardTokens, uint256[] memory rewards) = _checkRewards(poolId);
		MASTERCHEF.harvest(poolId, TREASURY);
		_transferMasterchefRewards(rewardTokens, rewards);

		emit RewardClaimed(address(MASTERCHEF.SUSHI()), pendingSushi);
	}

	/// @dev Will claim any non-sushi assets for specific poolId
	function _depositLPTokensToMasterChef(uint256 poolId, uint256 amount) private {
		MASTERCHEF.deposit(poolId, amount, address(this));
	}

	/// @dev Will claim any non-sushi assets for specific poolId
	function _withdrawLPTokensFromMasterChef(
		uint256 poolId,
		uint256 currentBalance,
		uint256 withdrawalAmount
	) private returns (bool) {
		if (currentBalance > 0) {
			if (currentBalance >= withdrawalAmount) {
				// Don't need to withdraw in this case
				return false;
			}
			withdrawalAmount = withdrawalAmount.sub(currentBalance);
		}

		(uint256 contractAmount, ) = MASTERCHEF.userInfo(poolId, address(this));
		require(contractAmount >= withdrawalAmount, "INVALID_AMOUNT");
		MASTERCHEF.withdraw(poolId, withdrawalAmount, address(this));
		return true;
	}

	/// @dev pendingTokens() returns arrays but will always only return one value
	/// @dev see https://github.com/sushiswap/sushiswap/blob/56cedd0e06a6cf665083b3a662f9f77b80303ebe/contracts/mocks/ComplexRewarder.sol#L97
	function _checkRewards(uint256 poolId) private returns (IERC20[] memory, uint256[] memory) {
		IComplexRewarder rewarder = MASTERCHEF.rewarder(poolId);
		if (address(rewarder) != address(0)) {
			return rewarder.pendingTokens(poolId, address(this), 0);
		}
		return (new IERC20[](0), new uint256[](0));
	}

	function _transferMasterchefRewards(IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) private {
		uint256 rewardAmountsLength = rewardAmounts.length;
		for (uint256 i = 0; i < rewardAmountsLength; ++i) {
			uint256 currentReward = rewardAmounts[i];
			if (currentReward > 0) {
				IERC20 token = rewardTokens[i];
				token.safeTransfer(TREASURY, currentReward);
				emit RewardClaimed(address(token), currentReward);
			}
		}
	}

	function _approve(address spender, IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}