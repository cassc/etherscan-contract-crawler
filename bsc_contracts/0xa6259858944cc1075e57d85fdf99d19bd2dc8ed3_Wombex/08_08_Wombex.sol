// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'forge-std/console.sol';

import 'solmate/utils/SafeTransferLib.sol';
import 'src/external/wombex/interfaces.sol';
import 'src/Guardian.sol';

contract Wombex is Guardian {
	using SafeTransferLib for ERC20;

	/// @notice underlying Wombat LP token, e.g. LP-BUSD for BUSD
	IAsset public immutable lpToken;

	/// @notice Wombex LP token, e.g. wmxLP-BUSD
	IBaseRewardPool public immutable wmxLpToken;

	/// @notice Wombex helper contract to deposit/withdraw + unstake from Wombat in one tx
	IPoolDepositor internal constant poolDepositor = IPoolDepositor(0xd7ae65005E4CFA15551ccc482807D3330E543289);
	/// @notice Wombex booster based off Convex booster
	IBooster internal constant booster = IBooster(0xE62c4454d1dd6B727eB7952888B31a74969086B8);

	address[] public rewards;

	error InvalidAsset();

	constructor(
		IAsset _lpToken,
		address[] memory _rewards,
		ERC20 _asset,
		address _owner
	) Guardian(_asset, _owner) {
		lpToken = _lpToken;
		rewards = _rewards;

		if (address(asset) != lpToken.underlyingToken()) revert InvalidAsset();

		uint256 pid = poolDepositor.lpTokenToPid(address(_lpToken));

		(, , , address crvRewards, ) = IBooster(booster).poolInfo(pid);
		wmxLpToken = IBaseRewardPool(crvRewards);

		asset.safeApprove(address(poolDepositor), type(uint256).max);
		ERC20(address(wmxLpToken)).safeApprove(address(poolDepositor), type(uint256).max);
	}

	function stakedAssets() public view override returns (uint256 _assets) {
		return wmxLpToken.balanceOf(address(this));
	}

	function _stake(uint256 _amount) internal override {
		uint256 balance = asset.balanceOf(address(this));

		uint256 amount = balance > _amount ? _amount : balance;

		_allow(asset, amount, address(poolDepositor));

		uint256 minLiquidity; // TODO

		poolDepositor.deposit(address(lpToken), amount, minLiquidity, true);
	}

	function _unstake(uint256 _amount) internal override returns (uint256 received) {
		uint256 stakedBalance = stakedAssets();

		uint256 amount = stakedBalance > _amount ? _amount : stakedBalance;

		_allow(ERC20(address(wmxLpToken)), amount, address(poolDepositor));

		uint256 balanceBefore = asset.balanceOf(address(this));

		/// minimum is handled by Guardian contract
		poolDepositor.withdraw(address(lpToken), _amount, 0, address(this));
		uint256 balanceAfter = asset.balanceOf(address(this));

		return balanceAfter - balanceBefore;
	}

	function _claimRewards() internal override {
		wmxLpToken.getReward(address(this), true);

		for (uint8 i = 0; i < rewards.length; ++i) {
			ERC20 reward = ERC20(rewards[i]);
			uint256 balance = reward.balanceOf(address(this));
			if (balance > 0) reward.safeTransfer(owner, balance);
		}
	}

	/// @dev helper function to reset allowances
	function _allow(
		ERC20 _token,
		uint256 _amount,
		address _spender
	) internal {
		uint256 allowance = _token.allowance(address(this), _spender);
		if (allowance < _amount) {
			_token.safeApprove(_spender, 0);
			_token.safeApprove(_spender, type(uint256).max);
		}
	}
}