// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStaking {
	/// @dev Emitted when a token is staked.
	event TokenStaked(address owner, uint256 indexed tokenId);
	/// @dev Emitted when a token is unstaked.
	event TokenUnstaked(address owner, uint256 indexed tokenId);

	/**
	 * @dev Stake a list of tokens.
	 * Each extra token should give a bonus of X% or Y% to staking points gain.
	 *
	 * @param tokenIds List of token IDs to stake.
	 */
	function stakeTokens(uint256[] calldata tokenIds) external;

	/**
	 * @dev Unstake a list of tokens.
	 * Progress is saved on the wallet, so tokens can be unstaked and staked again.
	 *
	 * @param tokenIds List of token IDs to unstake.
	 */
	function unstakeTokens(uint256[] calldata tokenIds) external;

	/**
	 * @dev Check if a token is staked.
	 *
	 * @param tokenId Token ID to check.
	 *
	 * @return True if token is staked.
	 */
	function isTokenStaked(uint256 tokenId) external view returns (bool);

	/**
	 * @dev Get current staking tier of a wallet.
	 *
	 * @param wallet Wallet address to check.
	 *
	 * @return Current staking tier.
	 */
	function getStakingTier(address wallet) external view returns (uint16);
}