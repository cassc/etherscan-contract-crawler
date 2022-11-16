// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import 'solmate/tokens/WETH.sol';
import '../external/convex/IBaseRewardPool.sol';
import '../external/convex/IBooster.sol';
import '../external/curve/IStableSwapEth.sol';
import '../Swap.sol';
import '../Strategy.sol';

contract WethStrategyConvexStEth is Strategy {
	using SafeTransferLib for ERC20;
	using FixedPointMathLib for uint256;

	/// @notice contract used to swap CRV/CVX rewards to ETH
	Swap public swap;

	/// @dev pid of stETH in Convex
	uint8 internal constant pid = 25;
	ERC20 private constant poolToken = ERC20(0x06325440D014e39736583c165C2963BA99fAf14E);
	IBaseRewardPool private constant reward = IBaseRewardPool(0x0A760466E1B4621579a82a39CB56Dda2F4E70f03);
	IStableSwapEth private constant pool = IStableSwapEth(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
	IBooster private constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

	ERC20 internal constant CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
	ERC20 internal constant CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
	ERC20 internal constant LDO = ERC20(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);

	ERC20[3] public rewards = [CRV, CVX, LDO];
	bool public shouldClaimExtras = true;

	/// @dev index of WETH in pool (technically just ETH)
	int128 internal constant INDEX_OF_ASSET = 0;
	/// @dev offset pool.get_virtual_price()'s 18 decimals
	uint256 internal constant NORMALIZED_DECIMAL_OFFSET = 1e18;

	/*///////////////
	/     Errors    /
	///////////////*/

	error ClaimRewardsFailed();
	error WithdrawAndUnwrapFailed();
	error DepositFailed();

	error NothingToInvest();

	constructor(
		Vault _vault,
		address _treasury,
		address[] memory _authorized,
		Swap _swap
	) Strategy(_vault, _treasury, _authorized) {
		swap = _swap;

		_approve();
	}

	receive() external payable {}

	/*///////////////////////
	/      Public View      /
	///////////////////////*/

	function totalAssets() public view override returns (uint256 assets) {
		uint256 rewardBalance = reward.balanceOf(address(this));
		if (rewardBalance == 0) return assets;
		assets += rewardBalance.mulDivDown(pool.get_virtual_price(), NORMALIZED_DECIMAL_OFFSET);
	}

	/*///////////////////////////////////////////
	/      Restricted Functions: onlyOwner      /
	///////////////////////////////////////////*/

	function changeSwap(Swap _swap) external onlyOwner {
		_unapproveSwap();
		swap = _swap;
		_approveSwap();
	}

	/*////////////////////////////////////////////////
	/      Restricted Functions: onlyAuthorized      /
	////////////////////////////////////////////////*/

	function reapprove() external onlyAuthorized {
		_unapprove();
		_approve();
	}

	function setShouldClaimExtras(bool _shouldClaimExtras) external onlyAuthorized {
		if (shouldClaimExtras = _shouldClaimExtras) revert AlreadyValue();
		shouldClaimExtras = _shouldClaimExtras;
	}

	/*/////////////////////////////
	/      Internal Override      /
	/////////////////////////////*/

	function _withdraw(uint256 _assets, address _receiver) internal override returns (uint256 received) {
		uint256 assets = totalAssets();
		if (assets == 0) return 0; // nothing to withdraw

		uint256 amount = _assets > assets ? assets : _assets;

		uint256 tokenAmount = amount.mulDivDown(reward.balanceOf(address(this)), totalAssets());

		if (!reward.withdrawAndUnwrap(tokenAmount, true)) revert WithdrawAndUnwrapFailed();

		uint256 balanceBefore = address(this).balance;
		pool.remove_liquidity_one_coin(tokenAmount, INDEX_OF_ASSET, _calculateSlippage(amount));
		unchecked {
			// older curve pools lack return values
			received = address(this).balance - balanceBefore;
		}

		WETH(payable(address(asset))).deposit{value: received}();

		asset.safeTransfer(_receiver, received);
	}

	function _harvest() internal override returns (uint256 received) {
		if (!reward.getReward(address(this), shouldClaimExtras)) revert ClaimRewardsFailed();

		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			ERC20 rewardToken = rewards[i];
			uint256 rewardBalance = rewardToken.balanceOf(address(this));

			if (rewardBalance == 0) continue;

			// send rewards to treasury
			if (fee > 0) {
				uint256 feeAmount = _calculateFee(rewardBalance);
				rewardToken.safeTransfer(treasury, feeAmount);
				rewardBalance -= feeAmount;
			}

			swap.swapTokens(address(rewardToken), address(asset), rewardBalance, 1);
		}

		received = asset.balanceOf(address(this));
		asset.safeTransfer(address(vault), received);
	}

	function _invest() internal override {
		uint256 assetBalance = asset.balanceOf(address(this));
		if (assetBalance == 0) revert NothingToInvest();

		uint256 virtualPrice = pool.get_virtual_price();

		uint256 min = _calculateSlippage(assetBalance.mulDivDown(NORMALIZED_DECIMAL_OFFSET, virtualPrice));

		WETH(payable(address(asset))).withdraw(assetBalance);

		pool.add_liquidity{value: assetBalance}([assetBalance, 0], min);

		uint256 poolTokens = poolToken.balanceOf(address(this));
		if (!booster.deposit(pid, poolTokens, true)) revert DepositFailed();
	}

	/*//////////////////////////////
	/      Internal Functions      /
	//////////////////////////////*/

	function _approve() internal {
		// approve deposit ETH into pool
		asset.safeApprove(address(pool), type(uint256).max);
		// approve deposit lpTokens into booster
		poolToken.safeApprove(address(booster), type(uint256).max);
		// approve withdraw lpTokens
		poolToken.safeApprove(address(pool), type(uint256).max);

		_approveSwap();
	}

	function _unapprove() internal {
		asset.safeApprove(address(pool), 0);
		poolToken.safeApprove(address(booster), 0);
		poolToken.safeApprove(address(pool), 0);

		_unapproveSwap();
	}

	// approve swap rewards to WETH
	function _unapproveSwap() internal {
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), 0);
		}
	}

	// approve swap rewards to WETH
	function _approveSwap() internal {
		uint8 length = uint8(rewards.length);
		for (uint8 i = 0; i < length; ++i) {
			rewards[i].safeApprove(address(swap), type(uint256).max);
		}
	}
}