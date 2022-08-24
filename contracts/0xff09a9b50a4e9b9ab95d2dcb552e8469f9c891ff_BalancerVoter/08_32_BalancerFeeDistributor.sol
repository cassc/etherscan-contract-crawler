// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface BalancerFeeDistributor {
	/// @notice Claims all pending distributions of the provided token for a user.
	/// @dev It's not necessary to explicitly checkpoint before calling this function, it will ensure the FeeDistributor
	/// is up to date before calculating the amount of tokens to be claimed.
	/// @param user - The user on behalf of which to claim.
	/// @param token - The ERC20 token address to be claimed.
	/// @return The amount of `token` sent to `user` as a result of claiming.
	function claimToken(address user, address token) external returns (uint256);

	/// @notice Claims a number of tokens on behalf of a user.
	/// @dev A version of `claimToken` which supports claiming multiple `tokens` on behalf of `user`.
	/// See `claimToken` for more details.
	/// @param user - The user on behalf of which to claim.
	/// @param tokens - An array of ERC20 token addresses to be claimed.
	/// @return An array of the amounts of each token in `tokens` sent to `user` as a result of claiming.
	function claimTokens(address user, address[] calldata tokens) external returns (uint256[] memory);
}