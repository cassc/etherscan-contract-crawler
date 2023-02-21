// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./BaseController.sol";
import "../interfaces/convex/IFraxBooster.sol";
import "../interfaces/convex/IFraxVoteProxy.sol";
import "../interfaces/convex/IFraxPoolRegistry.sol";
import "../interfaces/convex/IStakingProxyConvex.sol";
import "../interfaces/convex/IConvexStakingWrapperFrax.sol";
import "../interfaces/convex/IFraxUnifiedFarm.sol";

contract ConvexFraxController is BaseController {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	struct ExpectedReward {
		address token;
		uint256 minAmount;
	}

	event StakeLocked(bytes32 indexed kekId, uint256 pid, uint256 liquidity, uint256 secs);

	event VaultCreated(address indexed vault, uint256 pid);

	// solhint-disable-next-line var-name-mixedcase
	IFraxVoteProxy public immutable VOTER_PROXY;

	constructor(
		address _manager,
		address _accessControl,
		address _addressRegistry,
		address _fraxVoterProxy
	) public BaseController(_manager, _accessControl, _addressRegistry) {
		require(_fraxVoterProxy != address(0), "INVALID_FRAX_SYSTEM_BOOSTER_ADDRESS");

		VOTER_PROXY = IFraxVoteProxy(_fraxVoterProxy);
	}

	// @notice return pool informations
	/// @param pid Convex pool id
	function getPoolInfo(
		uint256 pid
	)
		external
		returns (
			address implementation,
			address stakingAddress,
			address stakingToken,
			address rewardsAddress,
			bool active
		)
	{
		return _getPoolInfo(pid);
	}

	function _getPoolInfo(
		uint256 pid
	)
		private
		returns (
			address implementation,
			address stakingAddress,
			address stakingToken,
			address rewardsAddress,
			bool active
		)
	{
		IFraxBooster operator = _getOperator();

		address poolRegistryAddress = operator.poolRegistry();
		(implementation, stakingAddress, stakingToken, rewardsAddress, active) = IFraxPoolRegistry(poolRegistryAddress)
			.poolInfo(pid);
	}

	/// @notice create a vault if none already exists and then deposits and stakes Curve LP tokens to Frax Convex
	/// @param pid Convex pool id
	/// @param lpToken LP token to deposit
	/// @param staking Convex reward contract associated with the Curve LP token
	/// @param amount Quantity of Curve LP token to deposit and stake
	function depositAndStakeLockedCurveLp(
		uint256 pid,
		address lpToken,
		address staking,
		uint256 amount,
		uint256 secs // Seconds it takes for entire amount to stake
	) external onlyManager onlyAddLiquidity returns (bytes32 kekId) {
		require(addressRegistry.checkAddress(lpToken, 0), "INVALID_LP_TOKEN");
		require(staking != address(0), "INVALID_STAKING_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");

		IFraxBooster operator = _getOperator();

		address poolRegistryAddress = operator.poolRegistry();
		(, address stakingAddress, address stakingToken, , ) = IFraxPoolRegistry(poolRegistryAddress).poolInfo(pid);
		address curveToken = IConvexStakingWrapperFrax(stakingToken).curveToken();
		require(lpToken == curveToken, "POOL_ID_LP_TOKEN_MISMATCH");
		require(staking == stakingAddress, "POOL_ID_STAKING_MISMATCH");

		address vaultAddress = _getVault(pid, address(this), false);
		if (vaultAddress == address(0)) {
			vaultAddress = operator.createVault(pid);
			emit VaultCreated(vaultAddress, pid);
		}

		_approve(vaultAddress, IERC20(lpToken), amount);

		uint256 balanceBefore = IFraxUnifiedFarm(stakingAddress).lockedLiquidityOf(vaultAddress);

		kekId = IStakingProxyConvex(vaultAddress).stakeLockedCurveLp(amount, secs);

		uint256 balanceChange = IFraxUnifiedFarm(stakingAddress).lockedLiquidityOf(vaultAddress).sub(balanceBefore);
		require(balanceChange == amount, "BALANCE_MUST_INCREASE");

		emit StakeLocked(kekId, pid, amount, secs);
	}

	/// @notice claims all Convex rewards associated with the target Curve LP token
	/// @param pid Convex pool id
	/// @param expectedRewards List of expected reward tokens and min amounts to receive on claim
	function claimRewards(
		uint256 pid,
		ExpectedReward[] calldata expectedRewards
	) external onlyManager onlyMiscOperation {
		address vaultAddress = _getVault(pid, address(this), true);
		require(expectedRewards.length > 0, "INVALID_EXPECTED_REWARDS");

		uint256 expectedRewardsLength = expectedRewards.length;
		uint256[] memory balancesBefore = new uint256[](expectedRewardsLength);

		for (uint256 i = 0; i < expectedRewardsLength; ++i) {
			ExpectedReward memory expectedReward = expectedRewards[i];
			require(expectedReward.token != address(0), "INVALID_REWARD_TOKEN_ADDRESS");
			require(expectedReward.minAmount > 0, "INVALID_MIN_REWARD_AMOUNT");
			balancesBefore[i] = IERC20(expectedReward.token).balanceOf(address(this));
		}

		IStakingProxyConvex(vaultAddress).getReward();

		for (uint256 i = 0; i < expectedRewardsLength; ++i) {
			ExpectedReward memory expectedReward = expectedRewards[i];
			uint256 balanceChange = IERC20(expectedReward.token).balanceOf(address(this)).sub(balancesBefore[i]);
			require(balanceChange >= expectedReward.minAmount, "BALANCE_MUST_INCREASE");
		}
	}

	/// @notice withdraws a Curve LP token from a Vault
	/// @dev does not claim available rewards
	/// @param kekId Vesting object id
	/// @param pid Convex pool id
	/// @param minAmount Minimum expected amount
	function withdrawLockedAndUnwrap(
		bytes32 kekId,
		uint256 pid,
		uint256 minAmount
	) external onlyManager onlyRemoveLiquidity {
		address vaultAddress = _getVault(pid, address(this), true);

		(, , address stakingToken, , ) = _getPoolInfo(pid);
		address curveToken = IConvexStakingWrapperFrax(stakingToken).curveToken();

		IFraxUnifiedFarm.LockedStake memory lockedStake = _getLockedStake(pid, address(this), kekId);

		uint256 balanceBefore = IERC20(curveToken).balanceOf(address(this));

		IStakingProxyConvex(vaultAddress).withdrawLockedAndUnwrap(kekId);

		uint256 balanceChange = IERC20(curveToken).balanceOf(address(this)).sub(balanceBefore);
		require(balanceChange == lockedStake.liquidity, "WITHDRAWN_AMT_MISMATCH");
		require(balanceChange >= minAmount, "BALANCE_MUST_INCREASE");
	}

	/// @notice returns list of vesting objects
	/// @param pid Convex pool id
	function lockedStakesOf(
		uint256 pid,
		address account
	) external returns (IFraxUnifiedFarm.LockedStake[] memory lockedStakes) {
		return _lockedStakesOf(pid, account);
	}

	/// @dev Make sure vault has our approval for given token (reset prev approval)
	function _approve(address spender, IERC20 token, uint256 amount) internal {
		uint256 currentAllowance = token.allowance(address(this), spender);
		if (currentAllowance > 0) {
			token.safeDecreaseAllowance(spender, currentAllowance);
		}
		token.safeIncreaseAllowance(spender, amount);
	}

	/// @notice returns current operator
	function _getOperator() private returns (IFraxBooster operator) {
		address operatorAddress = VOTER_PROXY.operator();
		operator = IFraxBooster(operatorAddress);
	}

	/// @notice returns vault for a given pool
	/// @param pid Convex pool id
	/// @param account Owner of the vault
	/// @param throwRequire Whether an error should be thrown if no vault has been found
	function _getVault(uint256 pid, address account, bool throwRequire) private returns (address vaultAddress) {
		IFraxBooster operator = _getOperator();
		address poolRegistryAddress = operator.poolRegistry();

		vaultAddress = IFraxPoolRegistry(poolRegistryAddress).vaultMap(pid, account);

		if (throwRequire) {
			require(vaultAddress != address(0), "VAULT_NOT_EXISTS");
		}
	}

	function _lockedStakesOf(
		uint256 pid,
		address account
	) private returns (IFraxUnifiedFarm.LockedStake[] memory lockedStakes) {
		address vaultAddress = _getVault(pid, account, true);

		(, address stakingAddress, , , ) = _getPoolInfo(pid);

		lockedStakes = IFraxUnifiedFarm(stakingAddress).lockedStakesOf(vaultAddress);
	}

	function _getLockedStake(
		uint256 pid,
		address account,
		bytes32 kekId
	) private returns (IFraxUnifiedFarm.LockedStake memory lockedStake) {
		IFraxUnifiedFarm.LockedStake[] memory lockedStakes = _lockedStakesOf(pid, account);

		for (uint256 i = 0; i < lockedStakes.length; ++i) {
			if (lockedStakes[i].kek_id == kekId) {
				return lockedStakes[i];
			}
		}
	}
}