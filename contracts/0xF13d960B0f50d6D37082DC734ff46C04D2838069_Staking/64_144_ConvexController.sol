// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./BaseController.sol";
import "../interfaces/convex/IConvexBooster.sol";
import "../interfaces/convex/IConvexBaseReward.sol";

contract ConvexController is BaseController {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	// solhint-disable-next-line var-name-mixedcase
	IConvexBooster public immutable BOOSTER;

	struct ExpectedReward {
		address token;
		uint256 minAmount;
	}

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		address _convexBooster
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(_convexBooster != address(0), "INVALID_BOOSTER_ADDRESS");

		BOOSTER = IConvexBooster(_convexBooster);
	}

	/// @notice deposits and stakes Curve LP tokens to Convex
	/// @param lpToken Curve LP token to deposit
	/// @param staking Convex reward contract associated with the Curve LP token
	/// @param poolId Convex poolId for the associated Curve LP token
	/// @param amount Quantity of Curve LP token to deposit and stake
	function depositAndStake(
		address lpToken,
		address staking,
		uint256 poolId,
		uint256 amount
	) external onlyManager onlyAddLiquidity {
		require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
		require(staking != address(0), "INVALID_STAKING_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");

		(address poolLpToken, , , address crvRewards, , ) = BOOSTER.poolInfo(poolId);
		require(lpToken == poolLpToken, "POOL_ID_LP_TOKEN_MISMATCH");
		require(staking == crvRewards, "POOL_ID_STAKING_MISMATCH");

		_approve(IERC20(lpToken), amount);

		uint256 beforeBalance = IConvexBaseRewards(staking).balanceOf(address(this));

		bool success = BOOSTER.deposit(poolId, amount, true);
		require(success, "DEPOSIT_AND_STAKE_FAILED");

		uint256 balanceChange = IConvexBaseRewards(staking).balanceOf(address(this)).sub(beforeBalance);
		require(balanceChange == amount, "BALANCE_MUST_INCREASE");
	}

	/// @notice withdraws a Curve LP token from Convex
	/// @dev does not claim available rewards
	/// @param lpToken Curve LP token to withdraw
	/// @param staking Convex reward contract associated with the Curve LP token
	/// @param amount Quantity of Curve LP token to withdraw
	function withdrawStake(address lpToken, address staking, uint256 amount) external onlyManager onlyRemoveLiquidity {
		require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
		require(staking != address(0), "INVALID_STAKING_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");

		uint256 beforeBalance = IERC20(lpToken).balanceOf(address(this));

		bool success = IConvexBaseRewards(staking).withdrawAndUnwrap(amount, false);
		require(success, "WITHDRAW_STAKE_FAILED");

		uint256 balanceChange = IERC20(lpToken).balanceOf(address(this)).sub(beforeBalance);
		require(balanceChange == amount, "BALANCE_MUST_INCREASE");
	}

	/// @notice claims all Convex rewards associated with the target Curve LP token
	/// @param staking Convex reward contract associated with the Curve LP token
	/// @param expectedRewards List of expected reward tokens and min amounts to receive on claim
	function claimRewards(
		address staking,
		ExpectedReward[] calldata expectedRewards
	) external onlyManager onlyMiscOperation {
		require(staking != address(0), "INVALID_STAKING_ADDRESS");
		require(expectedRewards.length > 0, "INVALID_EXPECTED_REWARDS");

		uint256[] memory beforeBalances = new uint256[](expectedRewards.length);

		for (uint256 i = 0; i < expectedRewards.length; ++i) {
			require(expectedRewards[i].token != address(0), "INVALID_REWARD_TOKEN_ADDRESS");
			require(expectedRewards[i].minAmount > 0, "INVALID_MIN_REWARD_AMOUNT");
			beforeBalances[i] = IERC20(expectedRewards[i].token).balanceOf(address(this));
		}

		require(IConvexBaseRewards(staking).getReward(), "CLAIM_REWARD_FAILED");

		for (uint256 i = 0; i < expectedRewards.length; ++i) {
			uint256 balanceChange = IERC20(expectedRewards[i].token).balanceOf(address(this)).sub(beforeBalances[i]);
			require(balanceChange >= expectedRewards[i].minAmount, "BALANCE_MUST_INCREASE");
		}
	}

	function _approve(IERC20 token, uint256 amount) internal {
		address spender = address(BOOSTER);
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}
}