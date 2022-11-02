// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'solmate/tokens/ERC20.sol';
import 'solmate/utils/SafeTransferLib.sol';

import './lib/Owned.sol';

abstract contract Guardian is Owned {
	using SafeTransferLib for ERC20;

	/// @notice base asset this strategy uses, e.g. USDC
	ERC20 public immutable asset;

	error BelowMinimum(uint256);

	constructor(ERC20 _asset, address _owner) Owned(_owner) {
		asset = _asset;
	}

	/*//////////////////////////
	/      View Functions      /
	//////////////////////////*/

	function freeAssets() public view returns (uint256 _assets) {
		return asset.balanceOf(address(this));
	}

	function stakedAssets() public view virtual returns (uint256 _assets);

	function totalAssets() external view returns (uint256 _assets) {
		return freeAssets() + stakedAssets();
	}

	/*///////////////////////////
	/      Owner Functions      /
	///////////////////////////*/

	/**
	 * @notice Deposits assets and stakes into strategy. Use an ERC20 transfer if you want to deposit
	 * without staking
	 * @param _amount Amount of assets to deposit
	 */
	function deposit(uint256 _amount) external onlyOwner {
		asset.safeTransferFrom(msg.sender, address(this), _amount);
		_stake(_amount);
	}

	/// @notice stake assets into strategy
	/// @dev should handle overflow, i.e. staking type(uint256).max should stake everything
	function stake(uint256 _amount) external onlyOwner {
		_stake(_amount);
	}

	/**
	 * @notice Withdraws assets to owner, first from free assets then from staked assets
	 * @param _amount Withdrawal amount. Handles overflow, so type(uint256).max withdraws everything
	 * @param _min Minimum amount to receive, safeguard against MEV exploits
	 * @return received Amount of assets received by owner
	 */
	function withdraw(uint256 _amount, uint256 _min) external onlyOwner returns (uint256 received) {
		uint256 free = freeAssets();
		uint256 staked = stakedAssets();
		uint256 fromFree;
		uint256 fromStaked;

		// first, withdraw from free assets
		if (free > 0) {
			fromFree = free > _amount ? _amount : free;
			unchecked {
				_amount -= fromFree;
				received += fromFree;
			}
		}

		// next, withdraw from staked assets
		if (_amount > 0 && staked > 0) {
			fromStaked = _amount > staked ? staked : _amount;
			received += _unstake(fromStaked);
		}

		if (received < _min) revert BelowMinimum(received);

		asset.safeTransfer(msg.sender, received);
	}

	/// @notice Claims strategy rewards from strategy and sends to owner
	function claimRewards() external onlyOwner {
		_claimRewards();
	}

	/// @notice Backup withdrawal in case of additional rewards/airdrops/etc uncovered by 'withdraw()'
	function withdrawERC20(ERC20 _token) external onlyOwner {
		uint256 balance = _token.balanceOf(address(this));
		_token.safeTransfer(msg.sender, balance);
	}

	/*////////////////////////////
	/      Worker Functions      /
	////////////////////////////*/

	/// @notice unstake assets from strategy
	/// @dev should handle overflow, i.e. unstaking type(uint256).max should unstake everything
	function unstake(uint256 _amount, uint256 _min) external onlyAuthorized returns (uint256 received) {
		received = _unstake(_amount);
		if (received < _min) revert BelowMinimum(received);
	}

	/*/////////////////////////////
	/      Internal Override      /
	/////////////////////////////*/

	/// @notice stake assets into strategy
	/// @dev should handle overflow, i.e. staking type(uint256).max should stake everything
	function _stake(uint256 _amount) internal virtual;

	/// @notice unstake assets from strategy
	/// @dev should handle overflow, i.e. unstaking type(uint256).max should unstake everything
	function _unstake(uint256 _amount) internal virtual returns (uint256 received);

	/// @notice claim strategy rewards for owner
	function _claimRewards() internal virtual;
}