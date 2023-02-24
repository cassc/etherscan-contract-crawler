// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

/// @title PSYCHO Limited
/// @notice A network of fashionable (limited) avatars
interface IPSYCHOLimited {
	/// @notice Set custom metadata for an avatar
	/// @param _avatarId to customize must be owner or approved owner
	/// @param _json should not have {}
	/// @dev Requires minimum `fee(1)`
	function metadata(uint256 _avatarId, string memory _json) external payable;

	/// @notice Mint and metadata fee
	/// @param _quantity multiplied by mint quantity or 1 for metadata
	/// @return Wei fee
	function fee(uint256 _quantity) external view returns (uint256);

	/// @notice Available avatars to mint
	/// @return Avatar stock
	function stock() external view returns (uint256);

	/// @notice Mints up to 1001 avatars
	/// @param _quantity max 20 per transaction
	/// @dev Requires `fee(_quantity)` and `stock() != 0`
	function mint(uint256 _quantity) external payable;

	/// @notice Burn an avatar
	/// @param _avatarId to burn must be owner or approved owner
	/// @dev Subtracts the avatar mint counter by 1
	function burn(uint256 _avatarId) external;
}