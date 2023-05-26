// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStaking {
	/// @dev Emitted when a token is staked.
	event TokenStaked(address owner, uint256 indexed tokenId);
	/// @dev Emitted when a token is unstaked.
	event TokenUnstaked(address owner, uint256 indexed tokenId);

	/**
	 * @dev Stake a list of tokens.
	 * Progress is saved on the wallet, so tokens can be unstaked and staked again.
	 * Each extra token should give a bonus of X% or Y% to staking points gain.
	 */
	function stakeTokens(uint256[] calldata tokenIds) external;

	/// @dev Unstake a list of tokens.
	function unstakeTokens(uint256[] calldata tokenIds) external;

	/// @dev Check if a token is currently staked.
	function isTokenStaked(uint256 tokenId) external view returns (bool isStaked);

	/// @dev Get currect staking tier of a wallet.
	function getStakingTier(address wallet) external view returns (uint16 tier);
}